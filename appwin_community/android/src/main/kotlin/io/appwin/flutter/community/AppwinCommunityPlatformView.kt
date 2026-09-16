package io.appwin.flutter.community

import android.app.Activity
import android.content.Context
import android.view.View
import androidx.compose.ui.ExperimentalComposeUiApi
import androidx.compose.ui.platform.ComposeView
import androidx.compose.ui.platform.ViewCompositionStrategy
import androidx.compose.ui.platform.createLifecycleAwareWindowRecomposer
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.LifecycleRegistry
import androidx.lifecycle.ViewModelStore
import androidx.lifecycle.ViewModelStoreOwner
import androidx.lifecycle.setViewTreeLifecycleOwner
import androidx.lifecycle.setViewTreeViewModelStoreOwner
import androidx.savedstate.SavedStateRegistry
import androidx.savedstate.SavedStateRegistryController
import androidx.savedstate.SavedStateRegistryOwner
import androidx.savedstate.setViewTreeSavedStateRegistryOwner
import io.appwin.community.AppwinCommunity
import io.flutter.plugin.common.MessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

/**
 * Factory for the native view embedded in the Flutter tree.
 *
 * This is what lets Dart's `AppwinCommunityView` render the feed full page in a
 * tab, rather than presenting it full screen.
 *
 * The activity is read when each view is created rather than captured once: it
 * changes on every rotation, and a destroyed activity held here would leak.
 */
internal class AppwinCommunityViewFactory(
  codec: MessageCodec<Any>,
  private val activityProvider: () -> Activity?,
) : PlatformViewFactory(codec) {

  companion object {
    /** Same identifier as on iOS and in Dart. */
    const val VIEW_TYPE: String = "appwin_community_view"
  }

  override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
    // The activity rather than the application context: Compose takes its
    // insets, theme and keyboard window from it. With the application context
    // alone, the feed's input field would not raise a keyboard.
    return AppwinCommunityPlatformView(activityProvider() ?: context)
  }
}

/**
 * The feed, hosted in a `ComposeView`.
 *
 * A `ComposeView` refuses to compose without lifecycle owners in its view tree,
 * and a Flutter PlatformView container provides none - the host app is not
 * necessarily a `ComponentActivity`. So we install one, owned by the view, whose
 * lifetime is exactly the PlatformView's.
 */
@OptIn(ExperimentalComposeUiApi::class)
internal class AppwinCommunityPlatformView(context: Context) : PlatformView {

  private val owner = PlatformViewOwner()

  private val composeView: ComposeView

  init {
    // Resumed before the view exists: the recomposer below subscribes to this
    // lifecycle as it is built, and one still INITIALIZED never starts.
    owner.start()

    composeView = ComposeView(context).apply {
      setViewTreeLifecycleOwner(owner)
      setViewTreeViewModelStoreOwner(owner)
      setViewTreeSavedStateRegistryOwner(owner)
      /*
       * Owners on this view are not enough. Lacking a parent composition
       * context, `AbstractComposeView` falls back on the *window* recomposer,
       * which it resolves from the root of the view tree - here Flutter's
       * `FlutterView`, which carries no lifecycle owner and never will. That
       * fallback throws `ViewTreeLifecycleOwner not found`, and the exception
       * crosses the JNI boundary as a hard abort rather than a Dart error.
       * Handing it a context built on our own lifecycle stops it ever looking.
       */
      setParentCompositionContext(
        createLifecycleAwareWindowRecomposer(lifecycle = owner.lifecycle),
      )
      // Composition follows our owner, not window attachment: Flutter detaches
      // and reattaches a platform view while scrolling, and a window-bound
      // strategy would rebuild the feed - losing scroll position and loaded
      // pages - on every round trip.
      setViewCompositionStrategy(ViewCompositionStrategy.DisposeOnViewTreeLifecycleDestroyed)
      setContent { AppwinCommunity.CommunityView() }
    }
  }

  override fun getView(): View = composeView

  override fun dispose() {
    owner.stop()
  }
}

/**
 * Minimal lifecycle owner for a view outside an activity.
 *
 * It is born resumed and dies with the view: a PlatformView has no intermediate
 * state to represent, since Flutter creates it when it shows it and destroys it
 * when it stops.
 */
private class PlatformViewOwner : LifecycleOwner, ViewModelStoreOwner, SavedStateRegistryOwner {

  private val lifecycleRegistry = LifecycleRegistry(this)
  private val savedStateController = SavedStateRegistryController.create(this)

  override val lifecycle: Lifecycle get() = lifecycleRegistry

  override val viewModelStore: ViewModelStore = ViewModelStore()

  override val savedStateRegistry: SavedStateRegistry
    get() = savedStateController.savedStateRegistry

  fun start() {
    // Restoration must precede the move to CREATED, or the registry throws on
    // the first saved-state consumer. There is nothing to restore here: the
    // view does not outlive the PlatformView.
    savedStateController.performAttach()
    savedStateController.performRestore(null)
    lifecycleRegistry.currentState = Lifecycle.State.RESUMED
  }

  fun stop() {
    lifecycleRegistry.currentState = Lifecycle.State.DESTROYED
    viewModelStore.clear()
  }
}
