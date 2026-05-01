// Focus.jsx, Prayer.jsx, AI.jsx, Notes.jsx, Habits.jsx, Profile.jsx, QuickCapture.jsx — remaining screens

const FocusHomeScreen = () => (
  <Screen nav="focus">
    <div className="slp-content">
      <TopBar title="Focus" subtitle="Deep work, calm mind" right={<button style={{ width: 44, height: 44, borderRadius: 14, background: '#fff', border: '1px solid var(--border-soft)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}><ISettings size={20}/></button>} onBack={false}/>

      <div style={{ borderRadius: 30, padding: 24, background: 'var(--grad-focus)', boxShadow: '0 16px 32px rgba(244,93,179,0.28)', textAlign: 'center', color: '#fff', position: 'relative', overflow: 'hidden' }}>
        <div style={{ fontSize: 13, fontWeight: 700, opacity: 0.9 }}>Pomodoro · Round 1 of 4</div>
        <div style={{ marginTop: 16, display: 'flex', justifyContent: 'center' }}>
          <Ring value={0} size={200} stroke={12} track="rgba(255,255,255,0.2)" gradient={['#fff','#FFD45C']}>
            <div style={{ fontFamily: 'var(--font-head)', fontWeight: 800, fontSize: 48, color: '#fff', letterSpacing: '-1px' }}>25:00</div>
            <div style={{ fontSize: 12, color: 'rgba(255,255,255,0.85)', fontWeight: 600 }}>Focus Time</div>
          </Ring>
        </div>
        <button style={{ marginTop: 20, height: 56, padding: '0 40px', borderRadius: 999, background: '#fff', color: 'var(--brand-pink)', border: 'none', fontWeight: 800, fontSize: 16, fontFamily: 'var(--font-head)', display: 'inline-flex', alignItems: 'center', gap: 8, cursor: 'pointer' }}>
          <IPlay size={18}/> Start Focus
        </button>
      </div>

      <div className="h3" style={{ marginTop: 22 }}>Quick presets</div>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10, marginTop: 10 }}>
        {[
          { t: '25 / 5', s: 'Pomodoro', sel: true },
          { t: '50 / 10', s: 'Deep Work' },
          { t: '90 min', s: 'Study Block' },
          { t: 'Custom', s: 'Set your own' },
        ].map((p, i) => (
          <div key={i} className="card" style={{ padding: 14, border: p.sel ? '2px solid var(--brand-pink)' : '1px solid var(--border-soft)' }}>
            <div className="h4">{p.t}</div>
            <div className="cap" style={{ marginTop: 2 }}>{p.s}</div>
          </div>
        ))}
      </div>

      <div className="h3" style={{ marginTop: 22 }}>Today</div>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 10, marginTop: 10 }}>
        {[{ n: '2h 15m', l: 'Focused' }, { n: '4', l: 'Sessions' }, { n: '7d', l: 'Streak' }].map((s, i) => (
          <div key={i} className="card" style={{ padding: 14, textAlign: 'center' }}>
            <div style={{ fontFamily: 'var(--font-head)', fontWeight: 800, fontSize: 18, background: 'var(--grad-action)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent' }}>{s.n}</div>
            <div className="cap" style={{ marginTop: 2 }}>{s.l}</div>
          </div>
        ))}
      </div>
    </div>
  </Screen>
);

const PrayerHomeScreen = () => {
  const prayers = [
    { name: 'Fajr', time: '4:42 AM', done: true },
    { name: 'Sunrise', time: '6:08 AM', done: true, sub: true },
    { name: 'Dhuhr', time: '12:15 PM', done: false, next: true },
    { name: 'Asr', time: '3:48 PM', done: false },
    { name: 'Maghrib', time: '6:32 PM', done: false },
    { name: 'Isha', time: '8:04 PM', done: false },
  ];
  return (
    <Screen nav="prayer">
      <div className="slp-content">
        <TopBar title="Prayer" subtitle="7 Shawwal 1446" onBack={false} right={<button style={{ width: 44, height: 44, borderRadius: 14, background: '#fff', border: '1px solid var(--border-soft)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}><ISettings size={20}/></button>}/>

        <div style={{ borderRadius: 30, padding: 22, background: 'linear-gradient(135deg, #6A4CFF 0%, #8B5CFF 60%, #B07CFF 100%)', boxShadow: 'var(--shadow-glow-purple)', color: '#fff', position: 'relative', overflow: 'hidden', minHeight: 180 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6, opacity: 0.9, fontSize: 12, fontWeight: 700 }}><IMoon size={14}/> Next Prayer</div>
          <div style={{ marginTop: 12, fontFamily: 'var(--font-head)', fontWeight: 800, fontSize: 32, letterSpacing: '-0.5px' }}>Dhuhr</div>
          <div style={{ fontFamily: 'var(--font-head)', fontWeight: 800, fontSize: 22, marginTop: 4 }}>12:15 PM</div>
          <div style={{ fontSize: 13, opacity: 0.9, marginTop: 4 }}>in 2h 34m · Cairo, Egypt</div>
          <button style={{ marginTop: 14, height: 40, padding: '0 18px', borderRadius: 999, background: '#fff', color: 'var(--brand-primary)', border: 'none', fontWeight: 700, fontSize: 13, display: 'inline-flex', alignItems: 'center', gap: 6, fontFamily: 'var(--font-head)' }}>
            <ICheckSm size={14}/> Mark as prayed
          </button>
          <svg style={{ position: 'absolute', right: -10, bottom: -10 }} width="160" height="120" viewBox="0 0 160 120">
            <path d="M80 18c-3 5-3 9 0 14 3-5 3-9 0-14Z" fill="#FFD45C" opacity="0.9"/>
            <path d="M30 110V60a35 35 0 0 1 70 0v50" fill="rgba(255,255,255,0.15)"/>
            <path d="M65 110V92a8 8 0 0 1 16 0v18" fill="rgba(255,255,255,0.25)"/>
            <circle cx="125" cy="40" r="14" fill="rgba(255,255,255,0.18)"/>
            <circle cx="135" cy="55" r="8" fill="rgba(255,255,255,0.15)"/>
          </svg>
        </div>

        <div className="card" style={{ padding: 6, marginTop: 14 }}>
          {prayers.map((p, i) => (
            <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '12px 12px', borderTop: i ? '1px solid var(--divider)' : 'none', background: p.next ? 'var(--surface-lavender)' : 'transparent', borderRadius: p.next ? 14 : 0 }}>
              <div style={{ width: 28, height: 28, borderRadius: '50%', background: p.done ? 'var(--success)' : (p.next ? 'var(--brand-primary)' : '#fff'), border: p.done || p.next ? 'none' : '2px solid var(--border-soft)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#fff' }}>
                {p.done && <ICheckSm size={14}/>}
                {p.next && <IMoon size={14}/>}
              </div>
              <div style={{ flex: 1 }}>
                <div style={{ fontFamily: 'var(--font-head)', fontWeight: 700, fontSize: 14, color: p.sub ? 'var(--text-muted)' : 'var(--text-primary)' }}>{p.name}</div>
                {p.sub && <div className="cap" style={{ fontSize: 10 }}>not a prayer · sunrise reference</div>}
              </div>
              <div style={{ fontFamily: 'var(--font-head)', fontWeight: 800, fontSize: 15, color: p.next ? 'var(--brand-primary)' : 'var(--text-primary)' }}>{p.time}</div>
            </div>
          ))}
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12, marginTop: 14 }}>
          <div className="card" style={{ padding: 16 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <div style={{ width: 32, height: 32, borderRadius: 10, background: 'var(--surface-lavender)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}><IBook size={18} color="#8B5CFF"/></div>
              <div className="h4">Quran Goal</div>
            </div>
            <div style={{ marginTop: 12, fontFamily: 'var(--font-head)', fontWeight: 800, fontSize: 22 }}>3 / 5 <span style={{ fontSize: 13, color: 'var(--text-muted)', fontWeight: 600 }}>pages</span></div>
            <div style={{ height: 6, background: '#EEE9FF', borderRadius: 999, marginTop: 8, overflow: 'hidden' }}>
              <div style={{ width: '60%', height: '100%', background: 'var(--grad-action)' }}/>
            </div>
            <div className="cap" style={{ marginTop: 8 }}>Daily reading</div>
          </div>
          <div className="card" style={{ padding: 16, position: 'relative', overflow: 'hidden' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <div style={{ width: 32, height: 32, borderRadius: 10, background: '#FFF4DC', display: 'flex', alignItems: 'center', justifyContent: 'center' }}><ICompass size={18} color="#FFB547"/></div>
              <div className="h4">Qibla</div>
            </div>
            <div style={{ display: 'flex', justifyContent: 'center', marginTop: 8 }}>
              <div style={{ position: 'relative', width: 80, height: 80, borderRadius: '50%', border: '2px solid var(--border-soft)' }}>
                <div style={{ position: 'absolute', top: '50%', left: '50%', transform: 'translate(-50%, -50%) rotate(45deg)', width: 4, height: 38, background: 'var(--grad-action)', borderRadius: 4, transformOrigin: 'center bottom', marginTop: -19 }}/>
                <div style={{ position: 'absolute', top: 6, left: '50%', transform: 'translateX(-50%)', fontSize: 9, fontWeight: 800, color: 'var(--text-muted)' }}>N</div>
              </div>
            </div>
            <div className="cap" style={{ textAlign: 'center', marginTop: 4 }}>136° SE</div>
          </div>
        </div>
      </div>
    </Screen>
  );
};

const AIChatScreen = () => (
  <Screen nav="home">
    <div className="slp-content">
      <TopBar title="AI Assistant" subtitle="Ready to help" right={<button style={{ width: 44, height: 44, borderRadius: 14, background: '#fff', border: '1px solid var(--border-soft)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}><IPlus size={20}/></button>}/>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
        <div style={{ alignSelf: 'flex-end', maxWidth: '78%', padding: '12px 16px', borderRadius: '20px 20px 4px 20px', background: 'var(--grad-action)', color: '#fff', fontSize: 14, fontWeight: 500, boxShadow: 'var(--shadow-glow-purple)' }}>
            Plan my afternoon. I have 3 tasks and Asr at 3:48 PM.
        </div>
        <div style={{ display: 'flex', gap: 8, alignItems: 'flex-end' }}>
          <div style={{ width: 32, height: 32, borderRadius: '50%', background: 'var(--grad-action)', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
            <ISpark size={16} color="#fff"/>
          </div>
          <div style={{ maxWidth: '80%', padding: '14px 16px', borderRadius: '20px 20px 20px 4px', background: '#fff', border: '1px solid var(--border-soft)', fontSize: 14, color: 'var(--text-primary)', fontWeight: 500, lineHeight: 1.5 }}>
            Here's a calm afternoon block, ending before Asr. You can edit anything before I save it.
          </div>
        </div>
        <div style={{ marginLeft: 40, marginTop: -4 }}>
          <div className="card" style={{ padding: 14, borderLeft: '4px solid var(--brand-primary)' }}>
            <div style={{ fontSize: 11, fontWeight: 700, color: 'var(--brand-primary)', textTransform: 'uppercase', letterSpacing: 1 }}>Suggested plan</div>
            {[
              { t: '1:00 PM', l: 'Refactor auth module', d: 'Focus · 60 min' },
              { t: '2:15 PM', l: 'Quick break + tea', d: '15 min' },
              { t: '2:30 PM', l: 'Research report', d: 'Focus · 60 min' },
              { t: '3:48 PM', l: 'Asr Prayer', d: 'Spiritual', p: true },
            ].map((s, i) => (
              <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '10px 0', borderTop: i ? '1px solid var(--divider)' : '1px solid var(--divider)', marginTop: i === 0 ? 10 : 0 }}>
                <div style={{ width: 50, fontSize: 11, fontWeight: 700, color: 'var(--text-muted)' }}>{s.t}</div>
                <div style={{ width: 8, height: 8, borderRadius: '50%', background: s.p ? 'var(--brand-violet)' : 'var(--brand-primary)' }}/>
                <div style={{ flex: 1 }}>
                  <div style={{ fontWeight: 700, fontSize: 13, fontFamily: 'var(--font-head)' }}>{s.l}</div>
                  <div className="cap">{s.d}</div>
                </div>
                {s.p && <IMoon size={14} color="var(--brand-violet)"/>}
              </div>
            ))}
            <div style={{ display: 'flex', gap: 8, marginTop: 12 }}>
              <button className="btn-primary" style={{ flex: 1, height: 44, fontSize: 13 }}>Apply plan</button>
              <button className="btn-secondary" style={{ height: 44, fontSize: 13 }}>Edit</button>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div style={{ position: 'absolute', left: 16, right: 16, bottom: 110, height: 56, borderRadius: 999, background: '#fff', border: '1px solid var(--border-soft)', boxShadow: 'var(--shadow-card)', display: 'flex', alignItems: 'center', padding: '0 6px 0 18px', gap: 10, zIndex: 4 }}>
      <span style={{ flex: 1, fontSize: 14, color: 'var(--text-muted)' }}>Ask anything…</span>
      <button style={{ width: 40, height: 40, borderRadius: '50%', background: 'var(--surface-lavender)', border: 'none', display: 'flex', alignItems: 'center', justifyContent: 'center' }}><IMic size={18} color="var(--brand-primary)"/></button>
      <button style={{ width: 44, height: 44, borderRadius: '50%', background: 'var(--grad-action)', border: 'none', display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: 'var(--shadow-glow-purple)' }}><IArrowR size={18} color="#fff"/></button>
    </div>
  </Screen>
);

const NotesMainScreen = () => {
  const notes = [
    { t: 'Q2 Roadmap brainstorm', p: 'Three pillars: speed, polish, AI. Build for trust before scale…', tag: 'Work', color: '#FFEAF6', tagColor: '#F45DB3', pin: true, h: 150 },
    { t: 'Groceries', list: ['Olive oil', 'Lentils', 'Tomatoes', 'Yogurt'], tag: 'Errand', color: '#FFF4DC', tagColor: '#B97600', h: 170 },
    { t: 'Reflection — week 14', p: 'Felt grounded most days. Prayer streak helped a lot. Need to sleep earlier on Tuesdays.', tag: 'Journal', color: '#E8FBFF', tagColor: '#39D7E8', h: 180 },
    { t: 'Meeting w/ Sarah', p: 'Discuss handoff timeline, design tokens, sprint cadence.', tag: 'Work', color: '#F0E9FF', tagColor: '#6A4CFF', h: 130 },
    { t: 'Gratitude', p: 'Family dinner. Sunny morning walk. Finished a hard task.', tag: 'Journal', color: '#E8FFF3', tagColor: '#1B8A53', h: 140 },
  ];
  return (
    <Screen nav="home">
      <div className="slp-content">
        <TopBar title="Notes" subtitle="32 notes · 4 pinned" onBack={false} right={<button style={{ width: 44, height: 44, borderRadius: 14, background: '#fff', border: '1px solid var(--border-soft)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}><ISearch size={20}/></button>}/>
        <div style={{ display: 'flex', gap: 8, marginBottom: 14, overflowX: 'auto' }} className="no-scroll">
          {['All', 'Pinned', 'Checklists', 'Voice', 'Archived'].map((c, i) => (
            <div key={c} className="chip" style={i === 0 ? { background: 'var(--grad-action)', color: '#fff' } : { background: '#fff', border: '1px solid var(--border-soft)', color: 'var(--text-secondary)' }}>{c}</div>
          ))}
        </div>
        <div style={{ columnCount: 2, columnGap: 10 }}>
          {notes.map((n, i) => (
            <div key={i} style={{ breakInside: 'avoid', marginBottom: 10, padding: 14, borderRadius: 22, background: n.color, position: 'relative', minHeight: n.h }}>
              {n.pin && <IPin size={14} color={n.tagColor} style={{ position: 'absolute', top: 12, right: 12 }}/>}
              <div style={{ fontFamily: 'var(--font-head)', fontWeight: 800, fontSize: 14, color: 'var(--text-primary)', paddingRight: n.pin ? 18 : 0 }}>{n.t}</div>
              {n.p && <div style={{ fontSize: 12, color: 'var(--text-secondary)', marginTop: 6, lineHeight: 1.45 }}>{n.p}</div>}
              {n.list && (
                <div style={{ marginTop: 8 }}>
                  {n.list.map((it, j) => (
                    <div key={j} style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 12, color: 'var(--text-secondary)', marginBottom: 4 }}>
                      <div style={{ width: 12, height: 12, borderRadius: 4, border: `1.5px solid ${n.tagColor}` }}/> {it}
                    </div>
                  ))}
                </div>
              )}
              <div style={{ marginTop: 10, fontSize: 10, fontWeight: 700, color: n.tagColor, textTransform: 'uppercase', letterSpacing: 0.5 }}>{n.tag}</div>
            </div>
          ))}
        </div>
      </div>
    </Screen>
  );
};

const HabitsMainScreen = () => {
  const habits = [
    { i: '🧘', t: 'Morning meditation', s: '7-day streak', g: 7, total: 7, done: true, color: '#25C68A', bg: '#E8FFF3' },
    { i: '💧', t: 'Drink 8 glasses of water', s: '5 / 8 today', g: 5, total: 8, color: '#39D7E8', bg: '#E8FBFF' },
    { i: '📖', t: 'Read 20 minutes', s: '3-day streak', g: 3, total: 1, done: true, color: '#FFB547', bg: '#FFF4DC' },
    { i: '🚶', t: '10k steps', s: '6,420 / 10,000', g: 6.4, total: 10, color: '#F45DB3', bg: '#FFEAF6' },
    { i: '🌙', t: 'Sleep before 11 PM', s: 'Tonight', g: 0, total: 1, color: '#8B5CFF', bg: '#F1ECFF' },
  ];
  return (
    <Screen nav="home">
      <div className="slp-content">
        <TopBar title="Habits" subtitle="Build the life you want" onBack={false} right={<button style={{ width: 44, height: 44, borderRadius: 14, background: 'var(--grad-action)', display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: 'var(--shadow-glow-purple)' }}><IPlus size={20} color="#fff"/></button>}/>
        <div className="card" style={{ padding: 18, display: 'flex', alignItems: 'center', gap: 16 }}>
          <Ring value={71} size={84} stroke={8} track="#F3EFFF" gradient={['#6A4CFF', '#F45DB3']}>
            <div style={{ fontFamily: 'var(--font-head)', fontWeight: 800, fontSize: 22 }}>5/7</div>
          </Ring>
          <div style={{ flex: 1 }}>
            <div className="h3">Today's habits</div>
            <div className="cap" style={{ marginTop: 4 }}>You're on a 7-day streak <IFlame size={12} color="#F45DB3" style={{ marginBottom: -2 }}/></div>
            <div style={{ display: 'flex', gap: 4, marginTop: 8 }}>
              {[1,1,1,1,1,1,1,0].map((d, i) => (
                <div key={i} style={{ width: 18, height: 6, borderRadius: 3, background: d ? 'var(--brand-primary)' : '#EEE9FF' }}/>
              ))}
            </div>
          </div>
        </div>
        <SectionHead title="Today" action="View all"/>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          {habits.map((h, i) => (
            <div key={i} className="card" style={{ padding: 14, display: 'flex', alignItems: 'center', gap: 12 }}>
              <div style={{ width: 44, height: 44, borderRadius: 14, background: h.bg, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 22 }}>{h.i}</div>
              <div style={{ flex: 1 }}>
                <div style={{ fontFamily: 'var(--font-head)', fontWeight: 700, fontSize: 14 }}>{h.t}</div>
                <div className="cap" style={{ marginTop: 2 }}>{h.s}</div>
                <div style={{ height: 4, background: '#EEE9FF', borderRadius: 999, marginTop: 6, overflow: 'hidden' }}>
                  <div style={{ width: `${(h.g / h.total) * 100}%`, height: '100%', background: h.color }}/>
                </div>
              </div>
              <div style={{ width: 36, height: 36, borderRadius: '50%', background: h.done ? h.color : 'transparent', border: h.done ? 'none' : `2px solid ${h.color}`, display: 'flex', alignItems: 'center', justifyContent: 'center', color: h.done ? '#fff' : h.color }}>
                {h.done ? <ICheckSm size={18}/> : <IPlus size={16}/>}
              </div>
            </div>
          ))}
        </div>
      </div>
    </Screen>
  );
};

const ProfileScreen = () => {
  const items = [
    [{ i: <IUser size={20} color="#6A4CFF"/>, t: 'Account', bg: '#F0E9FF' },
     { i: <ISettings size={20} color="#8B5CFF"/>, t: 'Appearance', s: 'Light', bg: '#F1ECFF' },
     { i: <IGlobe size={20} color="#39D7E8"/>, t: 'Language', s: 'English', bg: '#E8FBFF' }],
    [{ i: <IBell size={20} color="#FFB547"/>, t: 'Notifications', bg: '#FFF4DC' },
     { i: <IMoon size={20} color="#8B5CFF"/>, t: 'Prayer Preferences', bg: '#F1ECFF' },
     { i: <ITimer size={20} color="#F45DB3"/>, t: 'Focus Preferences', bg: '#FFEAF6' },
     { i: <IChart size={20} color="#4DA3FF"/>, t: 'Analytics', bg: '#EAF4FF' }],
    [{ i: <IShield size={20} color="#25C68A"/>, t: 'Privacy & Data', bg: '#E8FFF3' },
     { i: <IHelp size={20} color="#6F6B8E"/>, t: 'Help & Support', bg: '#EEE9FF' },
     { i: <ISpark size={20} color="#7C5CFF"/>, t: 'About', bg: '#F3EFFF' }],
  ];
  return (
    <Screen nav="profile">
      <div className="slp-content">
        <div className="h1" style={{ paddingTop: 4, marginBottom: 16 }}>Profile</div>
        <div className="card" style={{ padding: 18, display: 'flex', alignItems: 'center', gap: 14, background: 'var(--grad-ai)' }}>
          <Avatar initials="M" size={64}/>
          <div style={{ flex: 1 }}>
            <div className="h3">Mahmoud Hassan</div>
            <div className="cap" style={{ marginTop: 2 }}>mahmoud@email.com</div>
            <div style={{ display: 'flex', gap: 6, marginTop: 8 }}>
              <div className="chip soft-gold" style={{ height: 22, fontSize: 10 }}><IFlame size={10}/> 7d streak</div>
              <div className="chip" style={{ height: 22, fontSize: 10 }}>Lvl 4</div>
            </div>
          </div>
          <button style={{ width: 38, height: 38, borderRadius: 12, background: '#fff', border: '1px solid var(--border-soft)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}><IEdit size={16}/></button>
        </div>
        {items.map((group, gi) => (
          <div key={gi} className="card" style={{ padding: 4, marginTop: 14 }}>
            {group.map((it, i) => (
              <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '14px 14px', borderTop: i ? '1px solid var(--divider)' : 'none' }}>
                <div style={{ width: 36, height: 36, borderRadius: 12, background: it.bg, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>{it.i}</div>
                <div style={{ flex: 1, fontSize: 14, fontWeight: 600, fontFamily: 'var(--font-head)' }}>{it.t}</div>
                {it.s && <span className="cap">{it.s}</span>}
                <IArrowR size={16} color="var(--text-muted)"/>
              </div>
            ))}
          </div>
        ))}
        <button style={{ width: '100%', marginTop: 16, height: 50, borderRadius: 999, background: 'var(--error-soft)', border: 'none', color: 'var(--error)', fontWeight: 700, fontSize: 14, fontFamily: 'var(--font-head)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 8 }}>
          <ILogout size={16}/> Sign out
        </button>
      </div>
    </Screen>
  );
};

const QuickCaptureScreen = () => (
  <Screen showNav={false}>
    <div style={{ position: 'absolute', inset: 0, background: 'rgba(23,22,59,0.4)', backdropFilter: 'blur(6px)' }}/>
    <div style={{ position: 'absolute', left: 0, right: 0, bottom: 0, background: '#fff', borderRadius: '32px 32px 0 0', padding: '14px 20px 30px', boxShadow: '0 -8px 32px rgba(0,0,0,0.15)', minHeight: 540 }}>
      <div style={{ width: 40, height: 4, borderRadius: 999, background: 'var(--divider)', margin: '0 auto 16px' }}/>
      <div className="h2">Quick Capture</div>
      <div className="body" style={{ marginTop: 4 }}>What's on your mind?</div>
      <textarea placeholder="Type or speak…" style={{ width: '100%', minHeight: 100, marginTop: 16, borderRadius: 22, border: '1px solid var(--border-soft)', background: 'var(--surface-soft)', padding: 16, fontSize: 15, fontWeight: 500, fontFamily: 'var(--font-body)', resize: 'none', outline: 'none' }} defaultValue="Call mom tomorrow at 6pm and pick up groceries on the way home"/>
      <div style={{ display: 'flex', gap: 8, marginTop: 14, flexWrap: 'wrap' }}>
        {[
          { i: <IClipboard size={14}/>, t: 'Task', sel: true },
          { i: <IEdit size={14}/>, t: 'Note' },
          { i: <IBell size={14}/>, t: 'Reminder' },
          { i: <IFlame size={14}/>, t: 'Habit' },
          { i: <IMic size={14}/>, t: 'Voice' },
          { i: <ISpark size={14}/>, t: 'Ask AI' },
        ].map((c, i) => (
          <div key={i} className="chip" style={c.sel ? { background: 'var(--grad-action)', color: '#fff', height: 38, padding: '0 14px' } : { background: 'var(--surface-lavender)', color: 'var(--brand-primary)', height: 38, padding: '0 14px' }}>
            {c.i} {c.t}
          </div>
        ))}
      </div>
      <div className="card" style={{ padding: 14, marginTop: 16, background: 'var(--grad-ai)', borderLeft: '4px solid var(--brand-primary)' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6, color: 'var(--brand-primary)', fontWeight: 700, fontSize: 11, textTransform: 'uppercase', letterSpacing: 1 }}>
          <ISpark size={12}/> AI parsed
        </div>
        <div style={{ marginTop: 8, display: 'flex', flexDirection: 'column', gap: 8 }}>
          {[
            { l: 'Task 1', t: 'Call mom', m: 'Tomorrow · 6:00 PM · Reminder 30 min' },
            { l: 'Task 2', t: 'Pick up groceries', m: 'Tomorrow · After work' },
          ].map((p, i) => (
            <div key={i} style={{ padding: 10, borderRadius: 14, background: '#fff', border: '1px solid var(--border-soft)' }}>
              <div className="cap" style={{ fontSize: 10, fontWeight: 700, textTransform: 'uppercase' }}>{p.l}</div>
              <div style={{ fontFamily: 'var(--font-head)', fontWeight: 700, fontSize: 14, marginTop: 2 }}>{p.t}</div>
              <div className="cap" style={{ marginTop: 2 }}>{p.m}</div>
            </div>
          ))}
        </div>
      </div>
      <div style={{ display: 'flex', gap: 10, marginTop: 18 }}>
        <button className="btn-secondary" style={{ flex: 1 }}>Edit</button>
        <button className="btn-primary" style={{ flex: 2 }}>Save 2 tasks</button>
      </div>
    </div>
  </Screen>
);

Object.assign(window, { FocusHomeScreen, PrayerHomeScreen, AIChatScreen, NotesMainScreen, HabitsMainScreen, ProfileScreen, QuickCaptureScreen });
