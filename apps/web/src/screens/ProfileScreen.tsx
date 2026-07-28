import { signOut } from "../lib/auth";
import "./ProfileScreen.css";

interface Props {
  email: string | null;
}

export function ProfileScreen({ email }: Props) {
  return (
    <div className="profile-screen">
      <header className="dashboard-header">
        <span className="dashboard-wordmark">Profile</span>
      </header>

      <div className="profile-body fade-in-up">
        <div className="profile-avatar">
          {email ? email[0].toUpperCase() : "?"}
        </div>
        <p className="profile-email">{email ?? "Signed in"}</p>
        <p className="profile-role">Client account</p>

        <button type="button" className="profile-signout" onClick={() => signOut()}>
          Sign out
        </button>
      </div>
    </div>
  );
}
