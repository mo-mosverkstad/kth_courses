export function SignInView(props) {
    function emailACB(event) { props.change({ email: event.target.value }); }
    function passwordACB(event) { props.change({ password: event.target.value }); }
    function nameACB(event) { props.change({ displayName: event.target.value }); }
    function codeACB(event) { props.change({ code: event.target.value }); }

    function submitACB(event) {
        event.preventDefault();
        if (props.mode === "signUp") {
            props.signUp(props.form);
        } else {
            props.signIn(props.form);
        }
    }
    function toggleModeACB() {
        props.change({ mode: props.mode === "signUp" ? "signIn" : "signUp" });
    }
    function joinACB(event) {
        event.preventDefault();
        props.join(props.form.code);
    }

    return (
        <div>
            <h1>Catch Up!</h1>
            <p class="muted">Find the space that works for everyone, and see why.</p>

            <form class="card" onSubmit={submitACB}>
                <h2>{props.mode === "signUp" ? "Create an account" : "Sign in"}</h2>

                {props.mode === "signUp"
                    ? (
                        <div>
                            <label class="label" for="displayName">Your name</label>
                            <input id="displayName" value={props.form.displayName}
                                   onInput={nameACB} autocomplete="name" />
                        </div>
                    )
                    : null}

                <label class="label" for="email">Email</label>
                <input id="email" type="email" required value={props.form.email}
                       onInput={emailACB} autocomplete="email" />

                <label class="label" for="password">Password</label>
                <input id="password" type="password" required minlength="6"
                       value={props.form.password} onInput={passwordACB}
                       autocomplete={props.mode === "signUp" ? "new-password" : "current-password"} />

                {props.error ? <p class="warn" role="alert">{props.error}</p> : null}

                <div class="row" style={{ marginTop: "12px" }}>
                    <button class="btn" type="submit" disabled={props.busy}>
                        {props.busy
                            ? "Working..."
                            : (props.mode === "signUp" ? "Create account" : "Sign in")}
                    </button>
                    <button class="btn btn--ghost" type="button" onClick={toggleModeACB}>
                        {props.mode === "signUp" ? "I already have an account" : "Create an account"}
                    </button>
                </div>
            </form>

            <form class="card" onSubmit={joinACB}>
                <h2>Invited?</h2>
                <p class="muted">
                    Paste the code your group shared. You can also open the invite link
                    directly and you will land here, then continue straight into the meeting.
                </p>
                <label class="label" for="code">Invite code</label>
                <input id="code" value={props.form.code} onInput={codeACB} placeholder="ABC-123" />
                <button class="btn btn--ghost" type="submit"
                        style={{ marginTop: "12px" }}
                        disabled={!props.signedIn}>
                    Join
                </button>
                {!props.signedIn
                    ? <p class="faint">Sign in first, then the code will work.</p>
                    : null}
            </form>
        </div>
    );
}
