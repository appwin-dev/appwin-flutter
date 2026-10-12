package io.appwin.flutter.community

import android.app.Activity
import android.content.Context
import android.view.View
import android.view.WindowManager
import android.widget.FrameLayout
import androidx.activity.OnBackPressedDispatcher
import androidx.activity.OnBackPressedDispatcherOwner
import androidx.activity.compose.LocalOnBackPressedDispatcherOwner
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.ExperimentalComposeUiApi
import androidx.compose.ui.platform.ComposeView
import androidx.compose.ui.platform.ViewCompositionStrategy
import androidx.compose.ui.platform.createLifecycleAwareWindowRecomposer
import androidx.core.graphics.Insets
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
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

  /**
   * Flutter's PlatformView container often consumes system-bar insets before
   * Compose sees them. Mirror the RN [ComposeContainer]: wrap ComposeView and
   * re-dispatch so Community's `statusBarsPadding` / Scaffold `navigationBars`
   * match a native host.
   */
  private val container: FrameLayout

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
      setContent {
        // CommunityRoot uses BackHandler. FlutterActivity is not a
        // ComponentActivity, so AndroidCompositionLocals leave
        // LocalOnBackPressedDispatcherOwner null and BackHandler aborts the
        // process across JNI. Prefer the host when it is a dispatcher owner
        // (FlutterFragmentActivity), otherwise our PlatformView owner.
        val dispatcherOwner =
          (context as? OnBackPressedDispatcherOwner) ?: owner
        CompositionLocalProvider(
          LocalOnBackPressedDispatcherOwner provides dispatcherOwner,
        ) {
          // Showcase (and typical hosts) put a Flutter tab bar under this view.
          AppwinCommunity.CommunityView(hostOwnsBottomChrome = true)
        }
      }
    }

    container = FrameLayout(context).apply {
      addView(
        composeView,
        FrameLayout.LayoutParams(
          FrameLayout.LayoutParams.MATCH_PARENT,
          FrameLayout.LayoutParams.MATCH_PARENT,
        ),
      )
      ViewCompat.setOnApplyWindowInsetsListener(this) { v, insets ->
        // iOS child-VC safe areas are relative to the view's on-screen frame.
        // Android WindowInsets are window-global: clamp so status/IME only pad
        // where they actually overlap this PlatformView (avoids a second
        // status-bar gap when Flutter chrome already pushed the view down).
        var forCompose = insets.relativeTo(v).withoutBottomSystemBars()
        // Classic adjustResize shortens the root for the IME: forwarding IME
        // then double-lifts Compose imePadding(). Edge-to-edge Flutter keeps
        // the frame full-bleed and delivers IME as insets - keep those.
        if (hostUsesAdjustResize(context) && rootWasShortenedForIme(v, insets)) {
          forCompose = forCompose.withoutIme()
        }
        // Dispatch into ComposeView so its own listener (Compose WindowInsets)
        // sees the adjusted values - do not replace that listener.
        ViewCompat.dispatchApplyWindowInsets(composeView, forCompose)
        insets
      }
      addOnAttachStateChangeListener(object : View.OnAttachStateChangeListener {
        override fun onViewAttachedToWindow(v: View) {
          ViewCompat.requestApplyInsets(v)
        }

        override fun onViewDetachedFromWindow(v: View) = Unit
      })
      // Position can change after attach (tab bar, keyboard); re-clamp insets.
      addOnLayoutChangeListener { v, _, _, _, _, _, _, _, _ ->
        ViewCompat.requestApplyInsets(v)
      }
    }
  }

  override fun getView(): View = container

  override fun dispose() {
    owner.stop()
  }
}

/** True when the Activity shrinks its content for the IME (Flutter default). */
private fun hostUsesAdjustResize(context: Context): Boolean {
  val window = (context as? Activity)?.window ?: return true
  @Suppress("DEPRECATION")
  val mode = window.attributes.softInputMode and WindowManager.LayoutParams.SOFT_INPUT_MASK_ADJUST
  return mode == WindowManager.LayoutParams.SOFT_INPUT_ADJUST_RESIZE ||
    // Unspecified often behaves like resize on FlutterFragmentActivity.
    mode == WindowManager.LayoutParams.SOFT_INPUT_ADJUST_UNSPECIFIED
}

/**
 * Classic adjustResize shrinks the decor view by ~IME height. Edge-to-edge
 * hosts (Flutter 3.16+) keep the full display frame and only report IME insets.
 */
private fun rootWasShortenedForIme(view: View, insets: WindowInsetsCompat): Boolean {
  val imeBottom = insets.getInsets(WindowInsetsCompat.Type.ime()).bottom
  if (imeBottom <= 0) return false
  val rootHeight = view.rootView.height
  val screenHeight = view.resources.displayMetrics.heightPixels
  return rootHeight < screenHeight - imeBottom / 2
}

/**
 * Keeps only the portion of each system inset that overlaps [view], mirroring
 * UIKit safe-area behaviour for an embedded child view controller.
 */
private fun WindowInsetsCompat.relativeTo(view: View): WindowInsetsCompat {
  if (view.width <= 0 || view.height <= 0) return this
  val viewLoc = IntArray(2)
  view.getLocationOnScreen(viewLoc)
  val root = view.rootView
  val rootLoc = IntArray(2)
  root.getLocationOnScreen(rootLoc)
  val viewTop = viewLoc[1]
  val viewBottom = viewTop + view.height
  val viewLeft = viewLoc[0]
  val viewRight = viewLeft + view.width
  val windowTop = rootLoc[1]
  val windowBottom = windowTop + root.height
  val windowLeft = rootLoc[0]
  val windowRight = windowLeft + root.width

  fun clampTop(inset: Int): Int = maxOf(0, inset - (viewTop - windowTop))
  fun clampBottom(inset: Int): Int = maxOf(0, inset - (windowBottom - viewBottom))
  fun clampLeft(inset: Int): Int = maxOf(0, inset - (viewLeft - windowLeft))
  fun clampRight(inset: Int): Int = maxOf(0, inset - (windowRight - viewRight))

  fun clamp(source: Insets): Insets =
    Insets.of(clampLeft(source.left), clampTop(source.top), clampRight(source.right), clampBottom(source.bottom))

  val types = intArrayOf(
    WindowInsetsCompat.Type.statusBars(),
    WindowInsetsCompat.Type.navigationBars(),
    WindowInsetsCompat.Type.displayCutout(),
    WindowInsetsCompat.Type.systemBars(),
    WindowInsetsCompat.Type.ime(),
    WindowInsetsCompat.Type.mandatorySystemGestures(),
    WindowInsetsCompat.Type.tappableElement(),
    WindowInsetsCompat.Type.systemGestures(),
  )
  val builder = WindowInsetsCompat.Builder(this)
  for (type in types) {
    builder.setInsets(type, clamp(getInsets(type)))
  }
  return builder.build()
}

/**
 * Flutter hosts put their own bottom chrome (tab bar + SafeArea) under this
 * PlatformView. Community Scaffold still reads window-global `navigationBars`
 * and lifts the compose FAB by that height - a dark gap above the Flutter tab
 * bar. Full-screen Community uses [io.appwin.community.CommunityActivity], not
 * this embed, so stripping bottom system bars here is safe.
 */
private fun WindowInsetsCompat.withoutBottomSystemBars(): WindowInsetsCompat {
  val types = intArrayOf(
    WindowInsetsCompat.Type.navigationBars(),
    WindowInsetsCompat.Type.systemBars(),
    WindowInsetsCompat.Type.mandatorySystemGestures(),
    WindowInsetsCompat.Type.tappableElement(),
    WindowInsetsCompat.Type.systemGestures(),
    WindowInsetsCompat.Type.displayCutout(),
  )
  val builder = WindowInsetsCompat.Builder(this)
  for (type in types) {
    val source = getInsets(type)
    if (source.bottom == 0) continue
    builder.setInsets(type, Insets.of(source.left, source.top, source.right, 0))
  }
  return builder.build()
}

private fun WindowInsetsCompat.withoutIme(): WindowInsetsCompat =
  WindowInsetsCompat.Builder(this)
    .setInsets(WindowInsetsCompat.Type.ime(), Insets.NONE)
    .build()

/**
 * Minimal lifecycle owner for a view outside an activity.
 *
 * It is born resumed and dies with the view: a PlatformView has no intermediate
 * state to represent, since Flutter creates it when it shows it and destroys it
 * when it stops.
 */
private class PlatformViewOwner :
  LifecycleOwner,
  ViewModelStoreOwner,
  SavedStateRegistryOwner,
  OnBackPressedDispatcherOwner {

  private val lifecycleRegistry = LifecycleRegistry(this)
  private val savedStateController = SavedStateRegistryController.create(this)

  override val lifecycle: Lifecycle get() = lifecycleRegistry

  override val viewModelStore: ViewModelStore = ViewModelStore()

  override val savedStateRegistry: SavedStateRegistry
    get() = savedStateController.savedStateRegistry

  // Fallback dispatcher when the host Activity is not a ComponentActivity
  // (plain FlutterActivity). System back may still finish the Activity; this
  // mainly keeps BackHandler from crashing the process.
  override val onBackPressedDispatcher: OnBackPressedDispatcher =
    OnBackPressedDispatcher()

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
