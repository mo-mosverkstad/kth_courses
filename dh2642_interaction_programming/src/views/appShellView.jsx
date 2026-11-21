import { RouterView } from "vue-router";
import { NavigationView } from "./navigationView.jsx";
import { StatusBarView } from "./statusBarView.jsx";
import { ToastView } from "./toastView.jsx";
import { ConfirmDialogView } from "./confirmDialogView.jsx";
import { MeetupStagesView } from "./meetupStagesView.jsx";

// The shell: top bar, navigation, global status, and wherever the router
// mounts the current presenter. The data-breakpoint attribute is what the CSS
// uses to switch between the bottom tab bar, the icon rail and the sidebar.
export function AppShellView(props) {
    return (
        <div class="app" data-breakpoint={props.breakpoint} data-auth={props.authStatus}>
            <NavigationView items={props.navItems}
                            activePath={props.activePath}
                            navigate={props.navigate} />

            <div class="app__body">
                <header class="topbar">
                    <div>
                        <div class="topbar__title">{props.heading}</div>
                        <div class="topbar__sub">{props.subheading}</div>
                    </div>
                    <span class="topbar__spacer" />
                    {props.signedIn
                        ? <span class="topbar__sub">{props.displayName}</span>
                        : null}
                </header>

                <StatusBarView pendingLabels={props.pendingLabels}
                               progress={props.progress}
                               offline={props.offline}
                               authStatus={props.authStatus} />

                <main class="app__main">
                    {props.inMeetup
                        ? (
                            <MeetupStagesView stages={props.stages}
                                              activePath={props.activePath}
                                              subtitle={props.stageSubtitle}
                                              navigate={props.navigateStage} />
                        )
                        : null}
                    <RouterView />
                </main>
            </div>

            <ToastView toasts={props.toasts} dismiss={props.dismissToast} />
            <ConfirmDialogView dialog={props.confirmDialog}
                               confirm={props.confirmAction}
                               cancel={props.cancelConfirm} />
        </div>
    );
}
