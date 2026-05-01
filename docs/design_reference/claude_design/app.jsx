// Smart Life Planner — Canvas (entry)
// Wires every screen into a DesignCanvas with sections + iPhone frames.

const Phone = ({ children, w = 390, h = 844, scale = 1 }) => (
  <div style={{
    width: w, height: h, borderRadius: 48, overflow: 'hidden', position: 'relative',
    background: '#000', padding: 6,
    boxShadow: '0 30px 60px rgba(0,0,0,0.18), inset 0 0 0 2px #1a1a2a'
  }}>
    <div style={{ width: '100%', height: '100%', borderRadius: 42, overflow: 'hidden', position: 'relative', background: '#F8F6FF' }}>
      {children}
    </div>
  </div>
);

const App = () => (
  <DesignCanvas>
    <DCSection id="overview" title="Smart Life Planner" subtitle="Tasks · Focus · Prayer · AI · Notes · Habits — full hi-fi mocks for the entire product">
      <DCArtboard id="ov-home" label="Home (anchor)" width={410} height={870}><Phone><HomeScreen/></Phone></DCArtboard>
      <DCArtboard id="ov-prayer" label="Prayer Home" width={410} height={870}><Phone><PrayerHomeScreen/></Phone></DCArtboard>
      <DCArtboard id="ov-focus" label="Focus Active" width={410} height={870}><Phone><FocusActiveScreen/></Phone></DCArtboard>
      <DCArtboard id="ov-ai" label="AI Assistant" width={410} height={870}><Phone><AIChatScreen/></Phone></DCArtboard>
    </DCSection>

    <DCSection id="auth" title="Onboarding & Auth" subtitle="First-run, sign-in, goal selection">
      <DCArtboard id="au-splash" label="Splash" width={410} height={870}><Phone><SplashScreen/></Phone></DCArtboard>
      <DCArtboard id="au-welcome" label="Welcome / Value prop" width={410} height={870}><Phone><WelcomeScreen/></Phone></DCArtboard>
      <DCArtboard id="au-signin" label="Sign In" width={410} height={870}><Phone><SignInScreen/></Phone></DCArtboard>
      <DCArtboard id="au-onb" label="Onboarding · Goals" width={410} height={870}><Phone><OnboardingGoalsScreen/></Phone></DCArtboard>
    </DCSection>

    <DCSection id="tasks" title="Tasks Module" subtitle="Inbox, today list, quick capture, task creation, schedule view">
      <DCArtboard id="tk-list" label="Tasks · Today" width={410} height={870}><Phone><TasksMainScreen/></Phone></DCArtboard>
      <DCArtboard id="tk-create" label="Create Task" width={410} height={870}><Phone><CreateTaskScreen/></Phone></DCArtboard>
      <DCArtboard id="tk-sched" label="Schedule / Time-blocking" width={410} height={870}><Phone><ScheduleScreen/></Phone></DCArtboard>
      <DCArtboard id="tk-capture" label="Quick Capture (sheet)" width={410} height={870}><Phone><QuickCaptureScreen/></Phone></DCArtboard>
    </DCSection>

    <DCSection id="focus" title="Focus & Deep Work" subtitle="Pomodoro presets, immersive active state">
      <DCArtboard id="fo-home" label="Focus Home" width={410} height={870}><Phone><FocusHomeScreen/></Phone></DCArtboard>
      <DCArtboard id="fo-active" label="Focus Active (immersive)" width={410} height={870}><Phone><FocusActiveScreen/></Phone></DCArtboard>
    </DCSection>

    <DCSection id="prayer" title="Prayer & Spiritual" subtitle="Salah times, qibla, daily Quran goal">
      <DCArtboard id="pr-home" label="Prayer Home" width={410} height={870}><Phone><PrayerHomeScreen/></Phone></DCArtboard>
    </DCSection>

    <DCSection id="ai" title="AI Assistant" subtitle="Conversational planner with structured output cards">
      <DCArtboard id="ai-chat" label="AI Chat" width={410} height={870}><Phone><AIChatScreen/></Phone></DCArtboard>
    </DCSection>

    <DCSection id="notes" title="Notes & Journal" subtitle="Sticky-style notes grid, mood-tagged journal entry">
      <DCArtboard id="no-main" label="Notes Main" width={410} height={870}><Phone><NotesMainScreen/></Phone></DCArtboard>
      <DCArtboard id="no-journal" label="Journal Entry" width={410} height={870}><Phone><JournalEditorScreen/></Phone></DCArtboard>
    </DCSection>

    <DCSection id="habits" title="Habits" subtitle="Streak rings, today's checks, week strip">
      <DCArtboard id="hb-main" label="Habits Main" width={410} height={870}><Phone><HabitsMainScreen/></Phone></DCArtboard>
    </DCSection>

    <DCSection id="profile" title="Profile, Analytics & Notifications" subtitle="Settings stack, weekly review, notification center">
      <DCArtboard id="pf-main" label="Profile / Settings" width={410} height={870}><Phone><ProfileScreen/></Phone></DCArtboard>
      <DCArtboard id="pf-analytics" label="Analytics" width={410} height={870}><Phone><AnalyticsScreen/></Phone></DCArtboard>
      <DCArtboard id="pf-notif" label="Notification Center" width={410} height={870}><Phone><NotificationCenterScreen/></Phone></DCArtboard>
    </DCSection>
  </DesignCanvas>
);

ReactDOM.createRoot(document.getElementById('root')).render(<App/>);
