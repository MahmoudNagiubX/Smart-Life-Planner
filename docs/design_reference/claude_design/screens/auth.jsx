// AuthOnboarding.jsx — Splash, Welcome, SignIn, SignUp, Verify, Onboarding screens

const SplashScreen = () => (
  <Screen showNav={false} bg="linear-gradient(180deg, #F8F6FF 0%, #EEE9FF 100%)">
    <div style={{ position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 18 }}>
      <div className="logo-sq" style={{ width: 200, height: 200 }}/>
      <div style={{ fontFamily: 'var(--font-head)', fontWeight: 800, fontSize: 28, letterSpacing: '-0.5px' }}>Smart Life Planner</div>
      <div className="body" style={{ marginTop: -10 }}>Plan Smart. Live Better.</div>
      <div style={{ position: 'absolute', bottom: 80, display: 'flex', gap: 6 }}>
        {[0,1,2].map(i => <div key={i} style={{ width: 8, height: 8, borderRadius: '50%', background: 'var(--brand-primary)', opacity: 0.3 + i*0.25 }}/>)}
      </div>
    </div>
  </Screen>
);

const WelcomeScreen = () => (
  <Screen showNav={false}>
    <div className="slp-content" style={{ paddingBottom: 40 }}>
      <div style={{ marginTop: 20, height: 280, borderRadius: 30, background: 'linear-gradient(135deg, #FFFFFF 0%, #F8F6FF 100%)', position: 'relative', overflow: 'hidden', display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: 'var(--shadow-card)', border: '1px solid var(--border-soft)' }}>
        <div style={{ position: 'absolute', top: 30, left: 30, background: '#fff', borderRadius: 16, padding: '10px 14px', display: 'flex', alignItems: 'center', gap: 8, boxShadow: '0 4px 12px rgba(0,0,0,0.1)' }}>
          <IClipboard size={18} color="#6A4CFF"/>
          <span style={{ fontSize: 12, fontWeight: 700 }}>Tasks</span>
        </div>
        <div style={{ position: 'absolute', top: 50, right: 30, background: '#fff', borderRadius: 16, padding: '10px 14px', display: 'flex', alignItems: 'center', gap: 8 }}>
          <IMoon size={18} color="#8B5CFF"/>
          <span style={{ fontSize: 12, fontWeight: 700 }}>Prayer</span>
        </div>
        <div style={{ position: 'absolute', bottom: 60, left: 40, background: '#fff', borderRadius: 16, padding: '10px 14px', display: 'flex', alignItems: 'center', gap: 8 }}>
          <ITimer size={18} color="#F45DB3"/>
          <span style={{ fontSize: 12, fontWeight: 700 }}>Focus</span>
        </div>
        <div style={{ position: 'absolute', bottom: 40, right: 30, background: '#fff', borderRadius: 16, padding: '10px 14px', display: 'flex', alignItems: 'center', gap: 8 }}>
          <ISpark size={18} color="#FFD45C"/>
          <span style={{ fontSize: 12, fontWeight: 700 }}>AI</span>
        </div>
        <div className="logo-sq" style={{ width: 180, height: 180, filter: 'drop-shadow(0 18px 36px rgba(106,76,255,0.35))' }}/>
      </div>
      <div className="h1" style={{ marginTop: 24 }}>Organize your life with calm intelligence</div>
      <div className="body" style={{ marginTop: 10 }}>Tasks, habits, focus, prayer, notes, and AI planning in one beautiful system.</div>
      <div style={{ marginTop: 22, display: 'flex', flexDirection: 'column', gap: 12 }}>
        {[
          { i: <ICheck size={18} color="#6A4CFF"/>, t: 'Capture everything quickly' },
          { i: <ISpark size={18} color="#F45DB3"/>, t: 'Plan your day with AI support' },
          { i: <IMoon size={18} color="#8B5CFF"/>, t: 'Balance productivity with spiritual routines' },
        ].map((b,i)=>(
          <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <div style={{ width: 36, height: 36, borderRadius: 12, background: 'var(--surface-lavender)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>{b.i}</div>
            <div style={{ fontSize: 14, fontWeight: 600 }}>{b.t}</div>
          </div>
        ))}
      </div>
      <button className="btn-primary" style={{ width: '100%', marginTop: 28 }}>Get Started <IArrowR size={16}/></button>
      <div style={{ textAlign: 'center', marginTop: 14, color: 'var(--brand-primary)', fontSize: 14, fontWeight: 700 }}>I already have an account</div>
    </div>
  </Screen>
);

const SignInScreen = () => (
  <Screen showNav={false}>
    <div className="slp-content" style={{ paddingBottom: 40 }}>
      <div className="logo-sq" style={{ width: 96, height: 96, marginTop: 16 }}/>
      <div className="h1" style={{ marginTop: 24 }}>Welcome back</div>
      <div className="body" style={{ marginTop: 6 }}>Continue your calm productive day.</div>
      <div style={{ marginTop: 28, display: 'flex', flexDirection: 'column', gap: 14 }}>
        <div>
          <div className="label" style={{ marginBottom: 6, color: 'var(--text-secondary)' }}>Email</div>
          <div style={{ height: 56, borderRadius: 18, background: '#fff', border: '1px solid var(--border-soft)', display: 'flex', alignItems: 'center', padding: '0 18px', gap: 10 }}>
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#9A95B8" strokeWidth="2"><rect x="3" y="5" width="18" height="14" rx="2"/><path d="m3 7 9 6 9-6"/></svg>
            <span style={{ fontSize: 15, color: 'var(--text-primary)' }}>mahmoud@email.com</span>
          </div>
        </div>
        <div>
          <div className="label" style={{ marginBottom: 6, color: 'var(--text-secondary)' }}>Password</div>
          <div style={{ height: 56, borderRadius: 18, background: '#fff', border: '1px solid var(--border-soft)', display: 'flex', alignItems: 'center', padding: '0 18px', gap: 10 }}>
            <ILock size={18} color="#9A95B8"/>
            <span style={{ fontSize: 15, letterSpacing: 4, color: 'var(--text-primary)' }}>••••••••</span>
            <div style={{ flex: 1 }}/>
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#9A95B8" strokeWidth="2"><path d="M2 12s4-7 10-7 10 7 10 7-4 7-10 7-10-7-10-7Z"/><circle cx="12" cy="12" r="3"/></svg>
          </div>
        </div>
        <div style={{ textAlign: 'right', color: 'var(--brand-primary)', fontWeight: 700, fontSize: 13 }}>Forgot password?</div>
      </div>
      <button className="btn-primary" style={{ width: '100%', marginTop: 22 }}>Sign In</button>
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, margin: '20px 0' }}>
        <div style={{ flex: 1, height: 1, background: 'var(--divider)' }}/>
        <span className="cap">or continue with</span>
        <div style={{ flex: 1, height: 1, background: 'var(--divider)' }}/>
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
        <button style={{ height: 50, borderRadius: 999, background: '#fff', border: '1px solid var(--border-soft)', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8, fontWeight: 700, fontSize: 13, fontFamily: 'var(--font-head)' }}>
          <svg width="18" height="18" viewBox="0 0 18 18"><path fill="#4285F4" d="M17.6 9.2c0-.6-.1-1.2-.2-1.7H9v3.4h4.8c-.2 1.1-.8 2-1.8 2.6v2.1h2.9c1.7-1.5 2.7-3.8 2.7-6.4Z"/><path fill="#34A853" d="M9 18c2.4 0 4.5-.8 6-2.2l-2.9-2.1c-.8.5-1.8.9-3.1.9-2.4 0-4.4-1.6-5.1-3.7H.9v2.3A9 9 0 0 0 9 18Z"/><path fill="#FBBC05" d="M3.9 10.7c-.2-.5-.3-1.1-.3-1.7s.1-1.2.3-1.7V5H.9C.3 6.2 0 7.6 0 9s.3 2.8.9 4Z"/><path fill="#EA4335" d="M9 3.6c1.3 0 2.5.5 3.4 1.3l2.6-2.6C13.5.9 11.4 0 9 0A9 9 0 0 0 .9 5l3 2.3C4.6 5.2 6.6 3.6 9 3.6Z"/></svg>
          Google
        </button>
        <button style={{ height: 50, borderRadius: 999, background: '#fff', border: '1px solid var(--border-soft)', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8, fontWeight: 700, fontSize: 13, fontFamily: 'var(--font-head)' }}>
          <svg width="18" height="18" viewBox="0 0 24 24" fill="#000"><path d="M17.6 13c0-2.6 2.1-3.8 2.2-3.9-1.2-1.8-3.1-2-3.7-2-1.6-.2-3.1.9-3.9.9-.8 0-2-.9-3.4-.9-1.7 0-3.3 1-4.2 2.6-1.8 3.1-.5 7.7 1.3 10.2.9 1.2 1.9 2.6 3.3 2.5 1.3-.1 1.8-.9 3.4-.9 1.6 0 2 .9 3.4.8 1.4 0 2.3-1.2 3.2-2.5.7-.9 1.3-2 1.7-3.2-1.6-.6-3.3-1.8-3.3-4.6Zm-2.5-8.3c.7-.9 1.2-2.1 1-3.3-1.1.1-2.3.7-3.1 1.6-.7.7-1.3 2-1.1 3.1 1.2.1 2.5-.6 3.2-1.4Z"/></svg>
          Apple
        </button>
      </div>
      <div style={{ textAlign: 'center', marginTop: 22, fontSize: 13 }}>
        <span className="cap">Don't have an account? </span>
        <span style={{ color: 'var(--brand-primary)', fontWeight: 700 }}>Create account</span>
      </div>
    </div>
  </Screen>
);

const OnboardingGoalsScreen = () => {
  const goals = [
    { icon: '📚', label: 'Study', sel: true },
    { icon: '💼', label: 'Work', sel: true },
    { icon: '🌱', label: 'Self improvement' },
    { icon: '💪', label: 'Fitness' },
    { icon: '🕌', label: 'Spiritual growth', sel: true },
    { icon: '🎯', label: 'Better focus' },
    { icon: '✨', label: 'Better habits', sel: true },
    { icon: '🧘', label: 'Reduce overwhelm' },
  ];
  return (
    <Screen showNav={false}>
      <div className="slp-content" style={{ paddingBottom: 100 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginTop: 4 }}>
          <button style={{ width: 44, height: 44, borderRadius: 14, background: '#fff', border: '1px solid var(--border-soft)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}><IBack size={20}/></button>
          <div style={{ flex: 1, height: 6, background: '#EEE9FF', borderRadius: 999, overflow: 'hidden' }}>
            <div style={{ width: '55%', height: '100%', background: 'var(--grad-action)' }}/>
          </div>
          <span className="cap" style={{ fontWeight: 700 }}>5 / 9</span>
        </div>
        <div className="h1" style={{ marginTop: 22 }}>What are your main goals?</div>
        <div className="body" style={{ marginTop: 8 }}>Pick everything that matters. We'll personalize your dashboard.</div>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12, marginTop: 22 }}>
          {goals.map((g, i) => (
            <div key={i} style={{
              padding: 16, borderRadius: 22, background: g.sel ? 'var(--surface-lavender)' : '#fff',
              border: g.sel ? '2px solid var(--brand-primary)' : '1px solid var(--border-soft)',
              minHeight: 100, display: 'flex', flexDirection: 'column', justifyContent: 'space-between', position: 'relative'
            }}>
              <div style={{ fontSize: 28 }}>{g.icon}</div>
              <div style={{ fontWeight: 700, fontSize: 14, fontFamily: 'var(--font-head)' }}>{g.label}</div>
              {g.sel && <div style={{ position: 'absolute', top: 10, right: 10, width: 22, height: 22, borderRadius: '50%', background: 'var(--brand-primary)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}><ICheckSm size={14} color="#fff"/></div>}
            </div>
          ))}
        </div>
      </div>
      <div style={{ position: 'absolute', left: 20, right: 20, bottom: 30 }}>
        <button className="btn-primary" style={{ width: '100%' }}>Continue <IArrowR size={16}/></button>
      </div>
    </Screen>
  );
};

Object.assign(window, { SplashScreen, WelcomeScreen, SignInScreen, OnboardingGoalsScreen });
