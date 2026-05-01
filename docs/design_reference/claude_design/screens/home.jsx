// HomeScreen.jsx — Near-clone of App Preview

const HomeScreen = () => (
  <Screen nav="home">
    <div className="slp-content">
      {/* Header */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '4px 0 16px' }}>
        <div className="logo-sq" style={{ width: 56, height: 56 }}/>
        <div style={{ flex: 1 }}>
          <div style={{ fontFamily: 'var(--font-head)', fontWeight: 800, fontSize: 18, color: 'var(--text-primary)', letterSpacing: '-0.3px', display: 'flex', alignItems: 'center', gap: 4 }}>
            Good Morning, Mahmoud <span style={{ fontSize: 16 }}>☀️</span>
          </div>
          <div className="cap" style={{ marginTop: 2 }}>Tue, Apr 15 · 7 Shawwal 1446</div>
        </div>
        <button style={{ width: 44, height: 44, borderRadius: '50%', background: '#fff', border: '1px solid var(--border-soft)', display: 'flex', alignItems: 'center', justifyContent: 'center', position: 'relative', cursor: 'pointer' }}>
          <IBell size={20} color="var(--text-primary)"/>
          <span style={{ position: 'absolute', top: 10, right: 11, width: 8, height: 8, borderRadius: '50%', background: 'var(--error)', border: '2px solid #fff' }}/>
        </button>
        <Avatar initials="M"/>
      </div>

      {/* Daily Summary Card */}
      <div style={{
        position: 'relative', borderRadius: 28, overflow: 'hidden',
        background: 'var(--grad-brand)', padding: '20px 22px', minHeight: 175,
        boxShadow: '0 16px 32px rgba(106,76,255,0.32)', color: '#fff'
      }}>
        {/* sparkles */}
        <svg style={{ position: 'absolute', top: 18, right: 165, opacity: 0.9 }} width="14" height="14" viewBox="0 0 14 14"><path d="M7 0v5l5 2-5 2v5l-2-5-5-2 5-2Z" fill="#FFD45C"/></svg>
        <svg style={{ position: 'absolute', bottom: 22, right: 175, opacity: 0.7 }} width="8" height="8" viewBox="0 0 14 14"><path d="M7 0v5l5 2-5 2v5l-2-5-5-2 5-2Z" fill="#fff"/></svg>
        {/* faint chart bars */}
        <svg style={{ position: 'absolute', bottom: 0, left: 0, right: 0, opacity: 0.18 }} width="100%" height="60" viewBox="0 0 350 60" preserveAspectRatio="none">
          {[20,35,15,40,25,50,30,45,28,38,22,48,32,42].map((h,i)=>(
            <rect key={i} x={i*26+8} y={60-h} width="14" height={h} rx="3" fill="#fff"/>
          ))}
        </svg>
        <div style={{ position: 'relative', display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
          <div style={{ flex: 1, paddingRight: 8 }}>
            <div style={{ fontFamily: 'var(--font-head)', fontWeight: 800, fontSize: 22, lineHeight: '28px' }}>
              Today looks <span style={{ color: 'var(--brand-gold)' }}>balanced</span>
            </div>
            <div style={{ fontSize: 13, lineHeight: '19px', opacity: 0.92, marginTop: 8, fontWeight: 500 }}>
              Keep going! You're building<br/>consistency that matters.
            </div>
            <button style={{ marginTop: 14, height: 36, padding: '0 14px', borderRadius: 999, background: '#fff', color: 'var(--brand-primary)', border: 'none', fontWeight: 700, fontSize: 13, display: 'inline-flex', alignItems: 'center', gap: 6, cursor: 'pointer', fontFamily: 'var(--font-head)' }}>
              View your day <IArrowR size={14}/>
            </button>
          </div>
          <Ring value={72} size={108} stroke={9} track="rgba(255,255,255,0.22)" gradient={['#FFD45C', '#fff']}>
            <div style={{ fontFamily: 'var(--font-head)', fontWeight: 800, fontSize: 26, color: '#fff', lineHeight: 1 }}>72<span style={{ fontSize: 13 }}>%</span></div>
            <div style={{ fontSize: 10, color: 'rgba(255,255,255,0.85)', marginTop: 2, fontWeight: 600 }}>Day Progress</div>
          </Ring>
        </div>
      </div>

      {/* Two-card row: Next Prayer + Focus Session */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12, marginTop: 14 }}>
        {/* Next Prayer */}
        <div className="card" style={{ padding: 16, position: 'relative', overflow: 'hidden', minHeight: 210 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6, color: 'var(--brand-primary)', fontWeight: 700, fontSize: 12 }}>
            <IMoon size={16}/> <span style={{ color: 'var(--text-secondary)' }}>Next Prayer</span>
          </div>
          <div style={{ marginTop: 18, fontFamily: 'var(--font-head)', fontWeight: 800, fontSize: 18 }}>Dhuhr</div>
          <div style={{ marginTop: 4, fontFamily: 'var(--font-head)', fontWeight: 800, fontSize: 26, background: 'var(--grad-action)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent', display: 'inline-block' }}>
            12:15 <span style={{ fontSize: 14 }}>PM</span>
          </div>
          <div className="cap" style={{ marginTop: 2 }}>in 2h 34m</div>
          {/* Mosque illustration */}
          <svg style={{ position: 'absolute', right: -8, bottom: 50, opacity: 0.8 }} width="110" height="80" viewBox="0 0 110 80">
            <ellipse cx="60" cy="72" rx="55" ry="6" fill="#F3EFFF"/>
            <path d="M55 12c-2 4-2 7 0 10 2-3 2-6 0-10Z" fill="#FFD45C"/>
            <path d="M30 72V40a25 25 0 0 1 50 0v32" fill="#FFD45C" stroke="#8B5CFF" strokeWidth="1.5"/>
            <path d="M48 72V58a7 7 0 0 1 14 0v14" fill="#8B5CFF"/>
            <rect x="35" y="52" width="6" height="14" rx="3" fill="#8B5CFF"/>
            <rect x="69" y="52" width="6" height="14" rx="3" fill="#8B5CFF"/>
            <circle cx="20" cy="55" r="6" fill="#fff" opacity="0.7"/>
            <circle cx="95" cy="60" r="5" fill="#fff" opacity="0.7"/>
            <circle cx="100" cy="50" r="3" fill="#fff" opacity="0.6"/>
          </svg>
          <button style={{ position: 'absolute', left: 14, right: 14, bottom: 14, height: 38, borderRadius: 999, background: '#fff', border: '1px solid var(--border-soft)', color: 'var(--brand-primary)', fontWeight: 700, fontSize: 12, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 4, cursor: 'pointer', boxShadow: 'var(--shadow-soft)' }}>
            View Prayer Times <IArrowR size={12}/>
          </button>
        </div>

        {/* Focus Session */}
        <div className="card" style={{ padding: 16, minHeight: 210, position: 'relative' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6, color: 'var(--brand-pink)', fontWeight: 700, fontSize: 12 }}>
            <ITimer size={16}/> <span style={{ color: 'var(--text-secondary)' }}>Focus Session</span>
          </div>
          <div style={{ display: 'flex', justifyContent: 'center', marginTop: 12 }}>
            <Ring value={62} size={120} stroke={10} track="#F3EFFF" gradient={['#6A4CFF', '#FF6CA8']}>
              <div style={{ fontFamily: 'var(--font-head)', fontWeight: 800, fontSize: 24, color: 'var(--text-primary)', letterSpacing: '-0.5px' }}>25:00</div>
              <div style={{ fontSize: 10, color: 'var(--text-muted)', marginTop: 2, fontWeight: 600 }}>Focus Time</div>
            </Ring>
          </div>
          <button style={{ position: 'absolute', left: 14, right: 14, bottom: 14, height: 40, borderRadius: 999, background: 'var(--grad-action)', border: 'none', color: '#fff', fontWeight: 700, fontSize: 13, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6, cursor: 'pointer', boxShadow: 'var(--shadow-glow-pink)' }}>
            <IPlay size={14}/> Start Focus
          </button>
        </div>
      </div>

      {/* Today's Tasks */}
      <div className="card" style={{ padding: 18, marginTop: 14 }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <div style={{ width: 30, height: 30, borderRadius: 10, background: 'var(--feat-tasks-soft)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <IClipboard size={18} color="var(--brand-primary)"/>
            </div>
            <div className="h4">Today's Tasks</div>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 4, color: 'var(--brand-primary)', fontWeight: 700, fontSize: 12 }}>View all <IArrowR size={12}/></div>
        </div>
        {[
          { icon: '📋', iconBg: '#F0E9FF', iconColor: '#6A4CFF', title: 'Complete research report', sub: 'Work · High Priority', badge: 'In Progress', badgeStyle: 'soft', progress: 60 },
          { icon: '🏋️', iconBg: '#FFEAF6', iconColor: '#F45DB3', title: 'Workout at the gym', sub: 'Health · Build Strength', badge: 'Today', check: true },
          { icon: '📖', iconBg: '#F1ECFF', iconColor: '#8B5CFF', title: 'Study half Juz of Quran', sub: 'Spiritual · Learn & Reflect', badge: 'Today', check: true },
        ].map((t, i) => (
          <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '10px 0', borderTop: i ? '1px solid var(--divider)' : 'none' }}>
            <div style={{ width: 38, height: 38, borderRadius: 12, background: t.iconBg, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 18 }}>{t.icon}</div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontWeight: 700, fontSize: 13, color: 'var(--text-primary)', fontFamily: 'var(--font-head)' }}>{t.title}</div>
              <div className="cap" style={{ marginTop: 2 }}>{t.sub}</div>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <div style={{ height: 26, padding: '0 10px', borderRadius: 999, background: i === 0 ? '#F0E9FF' : '#FFEAF6', color: i === 0 ? '#6A4CFF' : '#D04590', fontSize: 11, fontWeight: 700, display: 'flex', alignItems: 'center' }}>{t.badge}</div>
              {t.progress ? (
                <div style={{ width: 36, height: 36, borderRadius: '50%', background: 'conic-gradient(var(--brand-primary) 0 60%, #EEE9FF 60% 100%)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                  <div style={{ width: 28, height: 28, borderRadius: '50%', background: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 9, fontWeight: 800, color: 'var(--brand-primary)' }}>60%</div>
                </div>
              ) : (
                <div style={{ width: 32, height: 32, borderRadius: '50%', border: '2px solid var(--brand-primary)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--brand-primary)' }}>
                  <ICheckSm size={16}/>
                </div>
              )}
            </div>
          </div>
        ))}
      </div>

      {/* Bottom row: Habits + AI */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12, marginTop: 14 }}>
        <div className="card" style={{ padding: 14, minHeight: 150 }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
              <IChart size={16} color="var(--brand-primary)"/>
              <div style={{ fontWeight: 700, fontSize: 13, fontFamily: 'var(--font-head)' }}>Habits Overview</div>
            </div>
            <IDots size={16} color="var(--text-muted)"/>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginTop: 12 }}>
            <Ring value={72} size={64} stroke={6} track="#F3EFFF" gradient={['#F45DB3', '#6A4CFF']}>
              <div style={{ fontFamily: 'var(--font-head)', fontWeight: 800, fontSize: 16, color: 'var(--text-primary)' }}>7</div>
              <div style={{ fontSize: 8, color: 'var(--text-muted)', fontWeight: 700, marginTop: -2, display: 'flex', alignItems: 'center', gap: 2 }}>
                Day <IFlame size={8} color="#F45DB3"/>
              </div>
            </Ring>
            <div style={{ flex: 1 }}>
              <div className="cap" style={{ marginBottom: 2 }}>Completed</div>
              <div style={{ fontFamily: 'var(--font-head)', fontWeight: 800, fontSize: 18 }}>5 / 7</div>
              <div style={{ height: 5, background: '#EEE9FF', borderRadius: 999, marginTop: 6, overflow: 'hidden' }}>
                <div style={{ width: '71%', height: '100%', background: 'var(--grad-action)', borderRadius: 999 }}/>
              </div>
              <div className="cap" style={{ marginTop: 6 }}>This Week</div>
            </div>
          </div>
        </div>

        <div className="card" style={{ padding: 14, minHeight: 150, position: 'relative', overflow: 'hidden', background: 'var(--grad-ai)' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
            <ISpark size={16} color="var(--brand-pink)"/>
            <div style={{ fontWeight: 700, fontSize: 13, fontFamily: 'var(--font-head)' }}>AI Suggestion</div>
          </div>
          <div style={{ marginTop: 8, fontSize: 11, lineHeight: '15px', color: 'var(--text-secondary)', fontStyle: 'italic', fontWeight: 500, paddingRight: 50 }}>
            <span style={{ color: 'var(--brand-pink)', fontSize: 18, fontWeight: 800 }}>"</span> Small steps today create big changes tomorrow. You've got this!
          </div>
          <div style={{ position: 'absolute', bottom: 12, left: 14, color: 'var(--brand-primary)', fontWeight: 700, fontSize: 11, display: 'flex', alignItems: 'center', gap: 4 }}>
            Ask AI anything <IArrowR size={11}/>
          </div>
          {/* robot */}
          <div style={{ position: 'absolute', right: 8, bottom: 6, width: 64, height: 64 }}>
            <svg viewBox="0 0 80 80" width="64" height="64">
              <ellipse cx="40" cy="74" rx="22" ry="3" fill="#EEE9FF"/>
              <rect x="22" y="28" width="36" height="34" rx="14" fill="url(#rg1)"/>
              <defs><linearGradient id="rg1" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stopColor="#B7A6FF"/><stop offset="1" stopColor="#6A4CFF"/></linearGradient></defs>
              <rect x="28" y="36" width="24" height="14" rx="6" fill="#1A1538"/>
              <circle cx="35" cy="43" r="2.5" fill="#fff"/>
              <circle cx="45" cy="43" r="2.5" fill="#fff"/>
              <circle cx="35.5" cy="43.5" r="1" fill="#6A4CFF"/>
              <circle cx="45.5" cy="43.5" r="1" fill="#6A4CFF"/>
              <rect x="36" y="22" width="8" height="8" rx="3" fill="#B7A6FF"/>
              <circle cx="40" cy="20" r="2.5" fill="#FFD45C"/>
              <rect x="18" y="40" width="6" height="14" rx="3" fill="#B7A6FF"/>
              <rect x="56" y="40" width="6" height="14" rx="3" fill="#B7A6FF"/>
              <path d="M30 56h20v6a4 4 0 0 1-4 4H34a4 4 0 0 1-4-4Z" fill="#8B5CFF"/>
            </svg>
          </div>
        </div>
      </div>
    </div>
  </Screen>
);

window.HomeScreen = HomeScreen;
