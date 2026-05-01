// FocusActive.jsx, Analytics.jsx, JournalEditor.jsx, NotificationCenter.jsx — extra screens

const FocusActiveScreen = () => (
  <Screen showNav={false} bg="linear-gradient(180deg, #2A1B6B 0%, #4F2E8A 50%, #6A2E7B 100%)" statusDark={true}>
    <div style={{ position: 'absolute', inset: 0, overflow: 'hidden' }}>
      <div style={{ position: 'absolute', top: -100, left: -100, width: 300, height: 300, borderRadius: '50%', background: 'radial-gradient(circle, rgba(244,93,179,0.4), transparent 70%)' }}/>
      <div style={{ position: 'absolute', bottom: -100, right: -100, width: 320, height: 320, borderRadius: '50%', background: 'radial-gradient(circle, rgba(106,76,255,0.45), transparent 70%)' }}/>
    </div>
    <div style={{ position: 'relative', padding: '20px 20px 40px', height: '100%', display: 'flex', flexDirection: 'column', color: '#fff' }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 30 }}>
        <button style={{ width: 44, height: 44, borderRadius: 14, background: 'rgba(255,255,255,0.12)', border: 'none', display: 'flex', alignItems: 'center', justifyContent: 'center', backdropFilter: 'blur(10px)' }}><IBack size={20} color="#fff"/></button>
        <div style={{ fontSize: 13, fontWeight: 700, opacity: 0.9 }}>FOCUSING</div>
        <button style={{ width: 44, height: 44, borderRadius: 14, background: 'rgba(255,255,255,0.12)', border: 'none', display: 'flex', alignItems: 'center', justifyContent: 'center' }}><ILock size={18} color="#fff"/></button>
      </div>
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center' }}>
        <div style={{ fontSize: 13, opacity: 0.8, marginBottom: 16 }}>Refactor auth module</div>
        <Ring value={48} size={280} stroke={12} track="rgba(255,255,255,0.12)" gradient={['#FFD45C', '#F45DB3']}>
          <div style={{ fontFamily: 'var(--font-head)', fontWeight: 800, fontSize: 64, color: '#fff', letterSpacing: '-2px' }}>13:00</div>
          <div style={{ fontSize: 13, opacity: 0.85, marginTop: 4, fontWeight: 600 }}>of 25:00</div>
        </Ring>
        <div style={{ marginTop: 20, fontSize: 12, opacity: 0.7, display: 'flex', alignItems: 'center', gap: 6 }}>
          <IMoon size={12}/> Asr in 1h 38m
        </div>
      </div>
      <div style={{ display: 'flex', gap: 14, justifyContent: 'center', marginBottom: 30 }}>
        <button style={{ width: 64, height: 64, borderRadius: '50%', background: 'rgba(255,255,255,0.14)', border: 'none', display: 'flex', alignItems: 'center', justifyContent: 'center', backdropFilter: 'blur(10px)' }}>
          <svg width="22" height="22" viewBox="0 0 24 24" fill="#fff"><rect x="6" y="5" width="4" height="14" rx="1.5"/><rect x="14" y="5" width="4" height="14" rx="1.5"/></svg>
        </button>
        <button style={{ width: 80, height: 80, borderRadius: '50%', background: '#fff', border: 'none', display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '0 0 40px rgba(255,255,255,0.4)' }}>
          <svg width="26" height="26" viewBox="0 0 24 24" fill="#6A2E7B"><rect x="6" y="6" width="12" height="12" rx="2"/></svg>
        </button>
        <button style={{ width: 64, height: 64, borderRadius: '50%', background: 'rgba(255,255,255,0.14)', border: 'none', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <IEdit size={22} color="#fff"/>
        </button>
      </div>
    </div>
  </Screen>
);

const AnalyticsScreen = () => (
  <Screen nav="profile">
    <div className="slp-content">
      <TopBar title="Analytics" subtitle="This week" right={<button className="btn-secondary" style={{ height: 38, padding: '0 12px', fontSize: 12 }}>Week ▾</button>} onBack={false}/>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
        {[
          { l: 'Tasks done', n: '34', d: '+8 vs last', c: '#6A4CFF', bg: 'var(--feat-tasks-soft)' },
          { l: 'Focus minutes', n: '12.5h', d: '4 streaks', c: '#F45DB3', bg: 'var(--feat-focus-soft)' },
          { l: 'Habits', n: '85%', d: '6 / 7 days', c: '#25C68A', bg: 'var(--feat-habits-soft)' },
          { l: 'Prayer', n: '32 / 35', d: '92% on time', c: '#8B5CFF', bg: 'var(--feat-prayer-soft)' },
        ].map((s, i) => (
          <div key={i} className="card" style={{ padding: 16 }}>
            <div className="cap">{s.l}</div>
            <div style={{ fontFamily: 'var(--font-head)', fontWeight: 800, fontSize: 26, color: s.c, marginTop: 4 }}>{s.n}</div>
            <div style={{ fontSize: 11, color: 'var(--text-secondary)', fontWeight: 600, marginTop: 2 }}>{s.d}</div>
            <div style={{ height: 4, borderRadius: 999, background: s.bg, marginTop: 10, overflow: 'hidden' }}>
              <div style={{ width: '70%', height: '100%', background: s.c }}/>
            </div>
          </div>
        ))}
      </div>
      <div className="card" style={{ padding: 18, marginTop: 14 }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <div className="h4">Focus & tasks</div>
          <div className="cap">Last 7 days</div>
        </div>
        <svg viewBox="0 0 320 140" style={{ width: '100%', height: 140, marginTop: 12 }}>
          {['M','T','W','T','F','S','S'].map((d, i) => {
            const focus = [40, 70, 55, 90, 80, 35, 60][i];
            const tasks = [50, 80, 65, 95, 75, 45, 70][i];
            return (
              <g key={i}>
                <rect x={i*44 + 14} y={130 - focus} width="14" height={focus} rx="4" fill="#F45DB3"/>
                <rect x={i*44 + 30} y={130 - tasks} width="14" height={tasks} rx="4" fill="#6A4CFF"/>
                <text x={i*44 + 28} y="138" fontSize="10" fill="#9A95B8" textAnchor="middle" fontWeight="700">{d}</text>
              </g>
            );
          })}
        </svg>
        <div style={{ display: 'flex', gap: 16, marginTop: 8 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 11, fontWeight: 600 }}><span style={{ width: 8, height: 8, borderRadius: 2, background: '#6A4CFF' }}/> Tasks</div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 11, fontWeight: 600 }}><span style={{ width: 8, height: 8, borderRadius: 2, background: '#F45DB3' }}/> Focus</div>
        </div>
      </div>
      <div className="card" style={{ padding: 18, marginTop: 14, background: 'var(--grad-ai)' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <ISpark size={16} color="var(--brand-pink)"/>
          <div className="h4">AI insight</div>
        </div>
        <div style={{ fontSize: 13, color: 'var(--text-secondary)', marginTop: 8, lineHeight: 1.5, fontWeight: 500 }}>
          You're most productive on <b style={{ color: 'var(--text-primary)' }}>Thursday mornings</b>. Try scheduling deep work blocks before 11am for better consistency.
        </div>
      </div>
    </div>
  </Screen>
);

const JournalEditorScreen = () => (
  <Screen showNav={false}>
    <div className="slp-content">
      <TopBar title="New entry" subtitle="Tue, Apr 15" right={<button className="btn-primary" style={{ height: 40, padding: '0 16px', fontSize: 13 }}>Save</button>}/>
      <div className="cap" style={{ fontWeight: 700, marginBottom: 8 }}>How are you feeling?</div>
      <div style={{ display: 'flex', gap: 8, marginBottom: 18 }}>
        {[
          { e: '😞', l: 'Low' },
          { e: '😐', l: 'Meh' },
          { e: '🙂', l: 'Good', sel: true },
          { e: '😊', l: 'Great' },
          { e: '🤩', l: 'Amazing' },
        ].map((m, i) => (
          <div key={i} style={{ flex: 1, padding: '10px 4px', borderRadius: 16, background: m.sel ? 'var(--grad-action)' : '#fff', border: m.sel ? 'none' : '1px solid var(--border-soft)', textAlign: 'center', color: m.sel ? '#fff' : 'var(--text-primary)', boxShadow: m.sel ? 'var(--shadow-glow-purple)' : 'none' }}>
            <div style={{ fontSize: 22 }}>{m.e}</div>
            <div style={{ fontSize: 10, fontWeight: 700, marginTop: 2 }}>{m.l}</div>
          </div>
        ))}
      </div>
      <div className="card" style={{ padding: 14, marginBottom: 14, background: 'var(--surface-soft)', borderLeft: '4px solid var(--brand-gold)' }}>
        <div className="cap" style={{ fontWeight: 700, color: 'var(--brand-gold)', textTransform: 'uppercase', fontSize: 10 }}>Today's prompt</div>
        <div style={{ fontSize: 14, fontFamily: 'var(--font-head)', fontWeight: 700, marginTop: 4 }}>What's one small thing that went well today?</div>
      </div>
      <textarea style={{ width: '100%', minHeight: 200, padding: 16, borderRadius: 22, border: '1px solid var(--border-soft)', background: '#fff', fontSize: 15, lineHeight: 1.6, fontFamily: 'var(--font-body)', resize: 'none', outline: 'none', color: 'var(--text-primary)' }} defaultValue="Finished the research draft a day early. Felt good to close my laptop before sunset and walk with Sara. The Dhuhr prayer in the park was peaceful — I want more days that feel like this."/>
      <div className="cap" style={{ fontWeight: 700, marginTop: 14, marginBottom: 8 }}>Grateful for</div>
      <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
        {['☀️ Sunny morning', '👨‍👩‍👧 Family', '☕ Coffee', '+ Add'].map((g, i) => (
          <div key={i} className="chip" style={i === 3 ? { background: '#fff', border: '1px dashed var(--border-soft)', color: 'var(--text-muted)' } : { background: 'var(--warning-soft)', color: '#B97600' }}>{g}</div>
        ))}
      </div>
    </div>
  </Screen>
);

const NotificationCenterScreen = () => {
  const groups = [
    { day: 'Today', items: [
      { i: <IMoon size={18} color="#8B5CFF"/>, bg: '#F1ECFF', t: 'Dhuhr prayer in 15 minutes', s: '12:00 PM · Tap to mark', time: '11:45' },
      { i: <ISpark size={18} color="#FFB547"/>, bg: '#FFF4DC', t: 'AI suggestion ready', s: 'Afternoon plan available', time: '11:02' },
      { i: <IClipboard size={18} color="#6A4CFF"/>, bg: '#F0E9FF', t: '"Research report" due today', s: 'Estimated 1h 30m left', time: '09:30' },
    ]},
    { day: 'Yesterday', items: [
      { i: <IFlame size={18} color="#F45DB3"/>, bg: '#FFEAF6', t: '7-day habit streak unlocked!', s: 'Morning meditation', time: '08:15' },
      { i: <ITimer size={18} color="#F45DB3"/>, bg: '#FFEAF6', t: 'Focus session complete', s: '50 min · Refactor auth module', time: '15:42' },
    ]},
  ];
  return (
    <Screen showNav={false}>
      <div className="slp-content">
        <TopBar title="Notifications" right={<div style={{ color: 'var(--brand-primary)', fontWeight: 700, fontSize: 13 }}>Mark all read</div>}/>
        <div style={{ display: 'flex', gap: 8, marginBottom: 16 }}>
          {['All', 'Tasks', 'Prayer', 'AI', 'Habits'].map((c, i) => (
            <div key={c} className="chip" style={i === 0 ? { background: 'var(--grad-action)', color: '#fff' } : { background: '#fff', border: '1px solid var(--border-soft)', color: 'var(--text-secondary)' }}>{c}</div>
          ))}
        </div>
        {groups.map((g, gi) => (
          <div key={gi} style={{ marginBottom: 16 }}>
            <div className="cap" style={{ fontWeight: 700, textTransform: 'uppercase', letterSpacing: 1, marginBottom: 8 }}>{g.day}</div>
            <div className="card" style={{ padding: 4 }}>
              {g.items.map((n, i) => (
                <div key={i} style={{ display: 'flex', alignItems: 'flex-start', gap: 12, padding: 14, borderTop: i ? '1px solid var(--divider)' : 'none' }}>
                  <div style={{ width: 38, height: 38, borderRadius: 12, background: n.bg, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>{n.i}</div>
                  <div style={{ flex: 1 }}>
                    <div style={{ fontWeight: 700, fontSize: 13, fontFamily: 'var(--font-head)' }}>{n.t}</div>
                    <div className="cap" style={{ marginTop: 2 }}>{n.s}</div>
                  </div>
                  <div className="cap" style={{ fontSize: 11 }}>{n.time}</div>
                </div>
              ))}
            </div>
          </div>
        ))}
      </div>
    </Screen>
  );
};

Object.assign(window, { FocusActiveScreen, AnalyticsScreen, JournalEditorScreen, NotificationCenterScreen });
