// Icons.jsx — Smart Life Planner icon set (rounded line, 2px stroke)
const Icon = ({ children, size = 22, color = 'currentColor', stroke = 2, fill = 'none', style = {} }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill={fill} stroke={color} strokeWidth={stroke} strokeLinecap="round" strokeLinejoin="round" style={style}>
    {children}
  </svg>
);

const IBell = (p) => <Icon {...p}><path d="M6 8a6 6 0 1 1 12 0c0 7 3 7 3 9H3c0-2 3-2 3-9Z"/><path d="M10 21a2 2 0 0 0 4 0"/></Icon>;
const IMoon = (p) => <Icon {...p}><path d="M21 12.8A8.5 8.5 0 1 1 11.2 3a6.5 6.5 0 0 0 9.8 9.8Z"/></Icon>;
const ITimer = (p) => <Icon {...p}><circle cx="12" cy="13" r="8"/><path d="M12 9v4l2.5 2"/><path d="M9 2h6"/></Icon>;
const ICheck = (p) => <Icon {...p}><circle cx="12" cy="12" r="9"/><path d="m8 12 3 3 5-6"/></Icon>;
const IClipboard = (p) => <Icon {...p}><rect x="6" y="4" width="12" height="17" rx="2"/><path d="M9 4V3a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v1"/><path d="m9 12 2 2 4-4"/></Icon>;
const IChart = (p) => <Icon {...p}><path d="M4 20V10"/><path d="M10 20V4"/><path d="M16 20v-7"/><path d="M22 20H2"/></Icon>;
const ISpark = (p) => <Icon {...p}><path d="M12 3v4M12 17v4M3 12h4M17 12h4M5.6 5.6l2.8 2.8M15.6 15.6l2.8 2.8M5.6 18.4l2.8-2.8M15.6 8.4l2.8-2.8"/></Icon>;
const IPlay = (p) => <Icon {...p} fill="currentColor"><path d="M8 5.5v13l11-6.5Z"/></Icon>;
const IArrowR = (p) => <Icon {...p}><path d="M5 12h14M13 5l7 7-7 7"/></Icon>;
const IPlus = (p) => <Icon {...p}><path d="M12 5v14M5 12h14"/></Icon>;
const IHome = (p) => <Icon {...p}><path d="M3 11 12 4l9 7v9a1 1 0 0 1-1 1h-5v-6h-6v6H4a1 1 0 0 1-1-1Z"/></Icon>;
const ICal = (p) => <Icon {...p}><rect x="3" y="5" width="18" height="16" rx="2"/><path d="M3 9h18M8 3v4M16 3v4"/></Icon>;
const IUser = (p) => <Icon {...p}><circle cx="12" cy="8" r="4"/><path d="M4 21a8 8 0 0 1 16 0"/></Icon>;
const IDots = (p) => <Icon {...p}><circle cx="5" cy="12" r="1.5" fill="currentColor"/><circle cx="12" cy="12" r="1.5" fill="currentColor"/><circle cx="19" cy="12" r="1.5" fill="currentColor"/></Icon>;
const ISearch = (p) => <Icon {...p}><circle cx="11" cy="11" r="7"/><path d="m20 20-3.5-3.5"/></Icon>;
const IFilter = (p) => <Icon {...p}><path d="M3 5h18M6 12h12M10 19h4"/></Icon>;
const IMic = (p) => <Icon {...p}><rect x="9" y="3" width="6" height="12" rx="3"/><path d="M5 11a7 7 0 0 0 14 0M12 18v3"/></Icon>;
const IFlame = (p) => <Icon {...p}><path d="M12 22a6 6 0 0 0 6-6c0-3-2-5-3-7-1 2-2 3-3 3-1-2-3-4-3-7-2 2-5 5-5 11a6 6 0 0 0 6 6Z"/></Icon>;
const ICompass = (p) => <Icon {...p}><circle cx="12" cy="12" r="9"/><path d="m15 9-2 5-5 2 2-5Z" fill="currentColor"/></Icon>;
const IBook = (p) => <Icon {...p}><path d="M4 4h7a3 3 0 0 1 3 3v13a2 2 0 0 0-2-2H4Z"/><path d="M20 4h-7a3 3 0 0 0-3 3v13a2 2 0 0 1 2-2h8Z"/></Icon>;
const ILock = (p) => <Icon {...p}><rect x="5" y="11" width="14" height="9" rx="2"/><path d="M8 11V8a4 4 0 0 1 8 0v3"/></Icon>;
const ISettings = (p) => <Icon {...p}><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.7 1.7 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-1.8-.3 1.7 1.7 0 0 0-1 1.5V21a2 2 0 1 1-4 0v-.1A1.7 1.7 0 0 0 9 19.4a1.7 1.7 0 0 0-1.8.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.7 1.7 0 0 0 .3-1.8 1.7 1.7 0 0 0-1.5-1H3a2 2 0 1 1 0-4h.1A1.7 1.7 0 0 0 4.6 9a1.7 1.7 0 0 0-.3-1.8l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.7 1.7 0 0 0 1.8.3H9a1.7 1.7 0 0 0 1-1.5V3a2 2 0 1 1 4 0v.1a1.7 1.7 0 0 0 1 1.5 1.7 1.7 0 0 0 1.8-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.7 1.7 0 0 0-.3 1.8V9a1.7 1.7 0 0 0 1.5 1H21a2 2 0 1 1 0 4h-.1a1.7 1.7 0 0 0-1.5 1Z"/></Icon>;
const IEdit = (p) => <Icon {...p}><path d="M12 20h9"/><path d="M16.5 3.5a2.1 2.1 0 1 1 3 3L7 19l-4 1 1-4Z"/></Icon>;
const IDumbbell = (p) => <Icon {...p}><path d="M6 6v12M2 9v6M18 6v12M22 9v6M6 12h12"/></Icon>;
const IMosque = (p) => <Icon {...p}><path d="M12 2c-1 2-1 3 0 4 1-1 1-2 0-4Z" fill="currentColor"/><path d="M5 21V11a7 7 0 0 1 14 0v10"/><path d="M5 21h14M9 21v-5a3 3 0 0 1 6 0v5"/></Icon>;
const IRobot = (p) => <Icon {...p}><rect x="5" y="8" width="14" height="11" rx="3"/><circle cx="9.5" cy="13" r="1" fill="currentColor"/><circle cx="14.5" cy="13" r="1" fill="currentColor"/><path d="M12 4v4M9 19v2M15 19v2"/></Icon>;
const IBack = (p) => <Icon {...p}><path d="M15 6l-6 6 6 6"/></Icon>;
const ITag = (p) => <Icon {...p}><path d="M3 12V5a2 2 0 0 1 2-2h7l9 9-9 9Z"/><circle cx="8" cy="8" r="1.5" fill="currentColor"/></Icon>;
const IPin = (p) => <Icon {...p}><path d="M12 2v6l4 4-4 4-4-4 4-4Z"/><path d="M12 16v6"/></Icon>;
const ICheckSm = (p) => <Icon {...p}><path d="m5 12 5 5 9-11"/></Icon>;
const IGlobe = (p) => <Icon {...p}><circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3a14 14 0 0 1 0 18M12 3a14 14 0 0 0 0 18"/></Icon>;
const IShield = (p) => <Icon {...p}><path d="M12 3 4 6v6c0 5 3.5 8.5 8 9 4.5-.5 8-4 8-9V6Z"/></Icon>;
const IHelp = (p) => <Icon {...p}><circle cx="12" cy="12" r="9"/><path d="M9.5 9a2.5 2.5 0 0 1 5 0c0 1.5-2.5 2-2.5 4M12 17h.01"/></Icon>;
const ILogout = (p) => <Icon {...p}><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4M16 17l5-5-5-5M21 12H9"/></Icon>;

Object.assign(window, {
  Icon, IBell, IMoon, ITimer, ICheck, IClipboard, IChart, ISpark, IPlay, IArrowR, IPlus,
  IHome, ICal, IUser, IDots, ISearch, IFilter, IMic, IFlame, ICompass, IBook,
  ILock, ISettings, IEdit, IDumbbell, IMosque, IRobot, IBack, ITag, IPin, ICheckSm,
  IGlobe, IShield, IHelp, ILogout
});
