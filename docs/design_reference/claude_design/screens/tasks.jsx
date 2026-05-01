// Tasks.jsx — Tasks Main, Today, Create Task, Task Details, Schedule

const TasksMainScreen = () => {
  const tabs = ['Inbox', 'Today', 'Upcoming', 'Projects', 'Done'];
  const tasks = [
    { icon: '📊', iconBg: '#F0E9FF', iconColor: '#6A4CFF', title: 'Complete research report', sub: 'Work · 2 subtasks', time: '4:00 PM', badge: 'High', badgeColor: '#FF4D6D', badgeBg: '#FFE8EE' },
    { icon: '📞', iconBg: '#FFEAF6', iconColor: '#F45DB3', title: 'Call with design team', sub: 'Work · Meeting', time: '11:30 AM', badge: 'Today', badgeColor: '#6A4CFF', badgeBg: '#F0E9FF' },
    { icon: '📖', iconBg: '#F1ECFF', iconColor: '#8B5CFF', title: 'Read chapter 4 of Atomic Habits', sub: 'Self · 30 min', time: '8:00 PM', badge: 'Today', badgeColor: '#6A4CFF', badgeBg: '#F0E9FF' },
    { icon: '🛒', iconBg: '#FFF4DC', iconColor: '#FFB547', title: 'Grocery shopping', sub: 'Errand · Weekly', time: 'Tomorrow', badge: 'Med', badgeColor: '#FFB547', badgeBg: '#FFF4DC' },
    { icon: '💻', iconBg: '#E8FBFF', iconColor: '#39D7E8', title: 'Refactor auth module', sub: 'Work · In Progress', time: 'Thu', badge: '40%', badgeColor: '#39D7E8', badgeBg: '#E8FBFF' },
  ];
  return (
    <Screen nav="tasks">
      <div className="slp-content">
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '4px 0 16px' }}>
          <div className="h1">Tasks</div>
          <div style={{ display: 'flex', gap: 8 }}>
            <button style={{ width: 44, height: 44, borderRadius: 14, background: '#fff', border: '1px solid var(--border-soft)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}><ISearch size={20}/></button>
            <button style={{ width: 44, height: 44, borderRadius: 14, background: '#fff', border: '1px solid var(--border-soft)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}><IFilter size={20}/></button>
          </div>
        </div>
        <div style={{ display: 'flex', gap: 8, overflowX: 'auto', marginBottom: 16 }} className="no-scroll">
          {tabs.map((t, i) => (
            <div key={t} className="chip" style={i === 1 ? { background: 'var(--grad-action)', color: '#fff', boxShadow: 'var(--shadow-glow-purple)' } : { background: '#fff', border: '1px solid var(--border-soft)', color: 'var(--text-secondary)' }}>{t}</div>
          ))}
        </div>
        {/* Day progress */}
        <div className="card" style={{ padding: 16, marginBottom: 14, display: 'flex', alignItems: 'center', gap: 14 }}>
          <Ring value={40} size={56} stroke={6} track="#F3EFFF" gradient={['#6A4CFF', '#F45DB3']}>
            <div style={{ fontFamily: 'var(--font-head)', fontWeight: 800, fontSize: 13 }}>2/5</div>
          </Ring>
          <div style={{ flex: 1 }}>
            <div className="h4">Today's progress</div>
            <div className="cap" style={{ marginTop: 2 }}>2 done · 3 remaining · 4h estimated</div>
          </div>
          <button className="btn-secondary" style={{ height: 38, padding: '0 12px', fontSize: 12 }}><ISpark size={14}/> AI Plan</button>
        </div>

        <div style={{ fontSize: 12, fontWeight: 700, color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: 1, margin: '6px 0 10px' }}>Morning</div>
        {tasks.map((t, i) => (
          <div key={i} className="card" style={{ padding: 14, marginBottom: 10, display: 'flex', alignItems: 'center', gap: 12 }}>
            <div style={{ width: 30, height: 30, borderRadius: '50%', border: '2px solid var(--border-soft)' }}/>
            <div style={{ width: 38, height: 38, borderRadius: 12, background: t.iconBg, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 18 }}>{t.icon}</div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontWeight: 700, fontSize: 14, fontFamily: 'var(--font-head)' }}>{t.title}</div>
              <div className="cap" style={{ marginTop: 2 }}>{t.sub} · {t.time}</div>
            </div>
            <div style={{ height: 24, padding: '0 10px', borderRadius: 999, background: t.badgeBg, color: t.badgeColor, fontSize: 11, fontWeight: 700, display: 'flex', alignItems: 'center' }}>{t.badge}</div>
          </div>
        ))}
      </div>
    </Screen>
  );
};

const CreateTaskScreen = () => (
  <Screen showNav={false}>
    <div className="slp-content">
      <TopBar title="New Task" right={<button className="btn-primary" style={{ height: 40, padding: '0 16px', fontSize: 13 }}>Save</button>}/>
      <div style={{ marginTop: 8 }}>
        <input placeholder="What do you need to do?" style={{ width: '100%', height: 60, borderRadius: 22, border: '1px solid var(--border-soft)', background: '#fff', padding: '0 18px', fontSize: 17, fontWeight: 600, fontFamily: 'var(--font-head)', outline: 'none' }} defaultValue="Finalize Q2 product roadmap"/>
        <textarea placeholder="Add a note or description…" style={{ width: '100%', minHeight: 90, borderRadius: 20, border: '1px solid var(--border-soft)', background: '#fff', padding: 16, fontSize: 14, fontFamily: 'var(--font-body)', resize: 'none', marginTop: 12, outline: 'none', color: 'var(--text-secondary)' }} defaultValue="Review feedback from leadership, lock priority list, and share with the team by EOD Friday."/>
      </div>
      <div className="card" style={{ padding: 4, marginTop: 14 }}>
        {[
          { i: <ICal size={20} color="#6A4CFF"/>, label: 'Due date', val: 'Fri, Apr 18 · 5:00 PM', color: '#6A4CFF' },
          { i: <IFlame size={20} color="#FF4D6D"/>, label: 'Priority', val: 'High', color: '#FF4D6D' },
          { i: <IClipboard size={20} color="#8B5CFF"/>, label: 'Project', val: 'Q2 Roadmap', color: '#8B5CFF' },
          { i: <IBell size={20} color="#FFB547"/>, label: 'Reminder', val: '30 min before', color: '#FFB547' },
          { i: <ITimer size={20} color="#F45DB3"/>, label: 'Estimated', val: '1h 30m', color: '#F45DB3' },
          { i: <ISpark size={20} color="#39D7E8"/>, label: 'Energy needed', val: 'High focus', color: '#39D7E8' },
        ].map((r, i) => (
          <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '14px 14px', borderTop: i ? '1px solid var(--divider)' : 'none' }}>
            <div style={{ width: 36, height: 36, borderRadius: 12, background: 'var(--surface-lavender)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>{r.i}</div>
            <div style={{ flex: 1 }}>
              <div className="cap">{r.label}</div>
              <div style={{ fontSize: 14, fontWeight: 700, marginTop: 1, color: 'var(--text-primary)' }}>{r.val}</div>
            </div>
            <IArrowR size={16} color="var(--text-muted)"/>
          </div>
        ))}
      </div>
      <button className="btn-secondary" style={{ width: '100%', marginTop: 14, height: 50, color: 'var(--brand-pink)' }}>
        <ISpark size={16} color="var(--brand-pink)"/> Improve with AI
      </button>
    </div>
  </Screen>
);

const ScheduleScreen = () => {
  const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  const blocks = [
    { time: '08:00', label: 'Morning Routine', sub: 'Habit · 30 min', color: '#25C68A', bg: '#E8FFF3' },
    { time: '09:00', label: 'Deep Work — Roadmap', sub: 'Focus · 90 min', color: '#6A4CFF', bg: '#F0E9FF', focus: true },
    { time: '10:30', label: 'Coffee break', sub: '15 min', color: '#FFB547', bg: '#FFF4DC' },
    { time: '12:15', label: 'Dhuhr Prayer', sub: 'Spiritual · 15 min', color: '#8B5CFF', bg: '#F1ECFF', prayer: true },
    { time: '13:00', label: 'Team standup', sub: 'Meeting · 30 min', color: '#F45DB3', bg: '#FFEAF6' },
    { time: '14:00', label: 'Refactor auth module', sub: 'Focus · 60 min', color: '#39D7E8', bg: '#E8FBFF', ai: true },
  ];
  return (
    <Screen nav="tasks">
      <div className="slp-content">
        <TopBar title="Schedule" subtitle="Tue, Apr 15" right={<button className="btn-secondary" style={{ height: 38, padding: '0 12px', fontSize: 12 }}><ISpark size={14}/> Replan</button>}/>
        <div style={{ display: 'flex', gap: 6, marginBottom: 14 }}>
          {days.map((d, i) => (
            <div key={i} style={{ flex: 1, height: 56, borderRadius: 16, background: i === 1 ? 'var(--grad-action)' : '#fff', color: i === 1 ? '#fff' : 'var(--text-primary)', border: i === 1 ? 'none' : '1px solid var(--border-soft)', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', boxShadow: i === 1 ? 'var(--shadow-glow-purple)' : 'none' }}>
              <div style={{ fontSize: 10, fontWeight: 600, opacity: 0.8 }}>{d}</div>
              <div style={{ fontSize: 16, fontWeight: 800, fontFamily: 'var(--font-head)' }}>{14 + i}</div>
            </div>
          ))}
        </div>
        <div style={{ position: 'relative', paddingLeft: 56 }}>
          <div style={{ position: 'absolute', left: 44, top: 8, bottom: 8, width: 2, background: 'var(--divider)' }}/>
          {blocks.map((b, i) => (
            <div key={i} style={{ marginBottom: 10, position: 'relative' }}>
              <div style={{ position: 'absolute', left: -56, top: 14, fontSize: 11, fontWeight: 700, color: 'var(--text-muted)' }}>{b.time}</div>
              <div style={{ position: 'absolute', left: -14, top: 16, width: 10, height: 10, borderRadius: '50%', background: b.color, border: '2px solid #fff', boxShadow: '0 0 0 2px ' + b.color + '33' }}/>
              <div className="card" style={{ padding: 14, display: 'flex', alignItems: 'center', gap: 10, borderLeft: `4px solid ${b.color}` }}>
                <div style={{ flex: 1 }}>
                  <div style={{ fontWeight: 700, fontSize: 14, fontFamily: 'var(--font-head)', display: 'flex', alignItems: 'center', gap: 6 }}>
                    {b.label}
                    {b.focus && <ITimer size={13} color="var(--brand-pink)"/>}
                    {b.prayer && <IMoon size={13} color="var(--brand-violet)"/>}
                    {b.ai && <ISpark size={13} color="var(--brand-gold)"/>}
                  </div>
                  <div className="cap" style={{ marginTop: 2 }}>{b.sub}</div>
                </div>
                {b.ai && <div className="chip soft-gold" style={{ height: 24, fontSize: 10 }}>AI</div>}
                {b.focus && <ILock size={14} color="var(--text-muted)"/>}
              </div>
            </div>
          ))}
        </div>
      </div>
    </Screen>
  );
};

Object.assign(window, { TasksMainScreen, CreateTaskScreen, ScheduleScreen });
