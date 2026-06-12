// English / Arabic UI strings, mirrored from the Flutter app_strings.dart.
export const STR = {
  // Navbar
  matches:        { en: 'Matches',      ar: 'المباريات' },
  leaderboard:    { en: 'Leaderboard',  ar: 'الترتيب' },
  myStats:        { en: 'My Stats',     ar: 'إحصائياتي' },
  signOut:        { en: 'Sign out',     ar: 'تسجيل الخروج' },

  // Scoring rules
  howPoints:      { en: 'How points work',                       ar: 'طريقة حساب النقاط' },
  exact3:         { en: 'Exact score = 3 points',                ar: 'نتيجة دقيقة = 3 نقاط' },
  correct1:       { en: 'Correct winner or draw = 1 point',      ar: 'فوز أو تعادل صحيح = 1 نقطة' },
  wrong0:         { en: 'Wrong pick = 0',                        ar: 'توقع خاطئ = 0' },
  saudiDouble:    { en: 'Saudi Arabia matches = double points',  ar: 'مباريات المنتخب السعودي = دبل نقاط' },
  lockHint:       { en: 'Predictions lock 1 hour before kickoff', ar: 'يُقفل التوقع قبل ساعة من المباراة' },

  // Countdown
  nextMatch:      { en: 'Next match',   ar: 'المباراة القادمة' },
  liveNow:        { en: 'Live now 🔴',  ar: 'المباراة الآن 🔴' },
  days:           { en: 'DAYS',     ar: 'يوم' },
  hours:          { en: 'HOURS',    ar: 'ساعة' },
  minutes:        { en: 'MINUTES',  ar: 'دقيقة' },
  seconds:        { en: 'SECONDS',  ar: 'ثانية' },
  hrs:            { en: 'HRS',  ar: 'ساعة' },
  min:            { en: 'MIN',  ar: 'دقيقة' },
  sec:            { en: 'SEC',  ar: 'ثانية' },

  // Match card
  savePick:       { en: 'Save pick',    ar: 'حفظ التوقع' },
  updatePick:     { en: 'Update pick',  ar: 'حفظ التعديل' },
  saved:          { en: 'Saved ✓',      ar: 'محفوظ ✓' },
  savedBang:      { en: 'Saved! ✓',     ar: 'تم الحفظ ✓' },
  saving:         { en: 'Saving…',      ar: 'جارٍ الحفظ…' },
  pickSaved:      { en: 'Pick saved!',          ar: 'تم حفظ توقعك' },
  unsavedChanges: { en: 'Unsaved changes',      ar: 'تعديل غير محفوظ' },
  yourPickSaved:  { en: 'Your pick is saved',   ar: 'توقعك محفوظ' },
  closed:         { en: 'Closed',       ar: 'مغلق' },
  result:         { en: 'Result',       ar: 'النتيجة' },
  yourPick:       { en: 'Your pick',    ar: 'توقعك' },
  noPrediction:   { en: 'No prediction made',   ar: 'لا يوجد توقع' },
  doubleBadge:    { en: 'Double points 🔥',      ar: 'دبل نقاط 🔥' },
  pts:            { en: 'pts',          ar: 'نقطة' },

  // Picks / colleague predictions
  picks:          { en: 'Picks',        ar: 'التوقعات' },
  colleaguePicks: { en: 'Employee picks',       ar: 'توقعات الموظفين' },
  picksHidden:    { en: 'Colleague picks appear after voting closes (1 hour before kickoff).',
                    ar: 'توقعات الزملاء تظهر بعد إغلاق نافذة التوقع (ساعة قبل البداية).' },
  noPicksYet:     { en: 'No picks yet',         ar: 'لا توجد توقعات بعد' },
  errLoadPicks:   { en: 'Could not load picks', ar: 'تعذّر تحميل التوقعات' },
  youLabel:       { en: 'You',          ar: 'أنت' },

  // Dashboard
  upcomingMatches:{ en: 'Upcoming Matches',     ar: 'المباريات القادمة' },
  pickDayHint:    { en: 'Pick a day to filter matches, or keep “All days”.',
                    ar: 'اختر يوماً لتصفية المباريات، أو اترك «جميع الأيام».' },
  loading:        { en: 'Loading…',     ar: 'جارٍ التحميل…' },
  couldNotLoad:   { en: 'Could not load matches.',  ar: 'تعذّر تحميل المباريات.' },
  allDays:        { en: 'All days',     ar: 'جميع الأيام' },
  noMatches:      { en: 'No upcoming matches',  ar: 'لا توجد مباريات قادمة' },
  loadMore:       { en: 'Load more',    ar: 'عرض المزيد' },

  // Past matches
  pastMatches:    { en: 'Past Matches', ar: 'المباريات السابقة' },
  noFinished:     { en: 'No finished matches yet', ar: 'لا توجد مباريات منتهية بعد' },
  finalResult:    { en: 'Final',        ar: 'النتيجة النهائية' },
  tapToSeeVotes:  { en: 'Tap to see everyone’s votes', ar: 'اضغط لعرض توقعات الجميع' },

  // Leaderboard user history
  history:        { en: 'Prediction history',  ar: 'سجل التوقعات' },
  theirPick:      { en: 'Pick',         ar: 'التوقع' },
  noHistory:      { en: 'No predictions yet',   ar: 'لا توجد توقعات بعد' },

  // Save feedback + identity
  savedToast:     { en: 'Prediction saved! ✓',  ar: 'تم حفظ التوقع! ✓' },
  errWindowToast: { en: 'Voting has closed for this match', ar: 'انتهى وقت التصويت لهذه المباراة' },
  errSaveToast:   { en: 'Could not save — please try again', ar: 'تعذّر الحفظ — حاول مجدداً' },
  whoAreYou:      { en: 'Who are you?',         ar: 'من أنت؟' },
  pickNameToSave: { en: 'Pick your name once to save predictions', ar: 'اختر اسمك مرة واحدة لحفظ توقعاتك' },
  confirmName:    { en: 'Confirm',      ar: 'تأكيد' },
  predictingAs:   { en: 'Predicting as', ar: 'تتوقّع باسم' },
  change:         { en: 'change',       ar: 'تغيير' },

  // Leaderboard page
  standingsTitle: { en: 'Leaderboard',  ar: 'الترتيب' },
  standingsSub:   { en: 'Live standings — auto-updating', ar: 'الترتيب اللحظي — يتحدّث تلقائياً' },
  noParticipants: { en: 'No participants yet',  ar: 'لا يوجد مشاركون بعد' },
  rankCol:        { en: '#',            ar: '#' },
  playerCol:      { en: 'Player',       ar: 'اللاعب' },
  correctShort:   { en: 'Correct',      ar: 'صحيحة' },
  exactShort:     { en: 'Exact',        ar: 'دقيقة' },

  // My Stats page
  selectName:     { en: 'Select your name to see your stats', ar: 'اختر اسمك لعرض إحصائياتك' },
  chooseName:     { en: 'Choose your name…',    ar: 'اختر اسمك…' },
  totalPoints:    { en: 'Total points',         ar: 'مجموع النقاط' },
  predictionsCount:{ en: 'Predictions',         ar: 'عدد التوقعات' },
  accuracy:       { en: 'Accuracy',             ar: 'دقة النتيجة' },
  exactPicks:     { en: 'Exact picks',          ar: 'توقعات دقيقة' },
  yourRank:       { en: 'Your rank',            ar: 'ترتيبك' },
  changeName:     { en: 'Change',               ar: 'تغيير' },
} as const;

export type StrKey = keyof typeof STR;
