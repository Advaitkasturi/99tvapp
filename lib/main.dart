// 99TV Broadcast & Studio Management — Flutter (single file)
// Needs only: shared_preferences (see pubspec.yaml). Run: flutter pub get && flutter run
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

const red = Color(0xFFE11D35), ink = Color(0xFF11151D), bgc = Color(0xFFF4F6FA), mut = Color(0xFF7C8494), tx = Color(0xFF202634);
typedef M = Map<String, dynamic>;

// ───────────────────────── Config ─────────────────────────
class F {
  final String k, l;
  final List<String>? o;
  final bool req, num, time;
  F(this.k, this.l, {this.o, this.req = false, this.num = false, this.time = false});
}

class Cfg {
  final String title, one;
  final List<String> cols;
  final List<F> f;
  final List<String> st;
  Cfg(this.title, this.one, this.cols, this.f, this.st);
}

final cfgs = <String, Cfg>{
  'anchors': Cfg('Anchor Schedule', 'Anchor', ['name', 'role', 'shows'], [F('name', 'Full name', req: true), F('role', 'Role', o: ['Senior Anchor', 'Lead Anchor', 'News Anchor', 'Business Anchor', 'Sports Anchor']), F('shows', 'Shows today', num: true), F('status', 'Status', o: ['Available', 'Assigned', 'On air', 'Off duty'])], ['Available', 'Assigned', 'On air', 'Off duty']),
  'drivers': Cfg('Driver Schedule', 'Driver', ['name', 'vehicle', 'location', 'trips'], [F('name', 'Full name', req: true), F('vehicle', 'Vehicle number', req: true), F('location', 'Location'), F('trips', 'Trips today', num: true), F('status', 'Status', o: ['Available', 'On road', 'Off duty'])], ['Available', 'On road', 'Off duty']),
  'cams': Cfg('Cameraman Schedule', 'Cameraman', ['name', 'specialty', 'shift'], [F('name', 'Full name', req: true), F('specialty', 'Specialty', o: ['Studio Camera', 'Field Camera', 'PTZ Camera', 'ENG News Camera']), F('shift', 'Shift (e.g. 09:00–17:00)'), F('status', 'Status', o: ['Available', 'Assigned', 'Off duty'])], ['Available', 'Assigned', 'Off duty']),
  'eds': Cfg('Production Team', 'Editor', ['name', 'specialty', 'pkg'], [F('name', 'Full name', req: true), F('specialty', 'Specialty', o: ['Video Editor', 'Senior Editor', 'Graphics']), F('pkg', 'Assigned package'), F('status', 'Status', o: ['Available', 'Assigned', 'Editing', 'Review'])], ['Available', 'Assigned', 'Editing', 'Review']),
  'bookings': Cfg('Bookings', 'Booking', ['program', 'studio', 'anchor', 'start', 'end'], [F('program', 'Program name', req: true), F('studio', 'Studio'), F('anchor', 'Anchor'), F('start', 'Start (HH:MM)', time: true), F('end', 'End (HH:MM)', time: true), F('status', 'Status', o: ['Scheduled', 'Upcoming', 'On air', 'Completed'])], ['Scheduled', 'Upcoming', 'On air', 'Completed']),
  'assigns': Cfg('Assignments', 'Assignment', ['program', 'time', 'studio', 'anchor', 'cameraman', 'editor', 'driver'], [F('program', 'Program / assignment', req: true), F('time', 'Time (e.g. 11:00–12:00)'), F('studio', 'Studio'), F('anchor', 'Anchor'), F('cameraman', 'Cameraman'), F('editor', 'Editor'), F('driver', 'Driver'), F('status', 'Status', o: ['Needs driver', 'Scheduled', 'Ready', 'On air', 'Completed'])], ['Needs driver', 'Scheduled', 'Ready', 'On air', 'Completed']),
  'studios': Cfg('Studio Management', 'Studio', ['name'], [F('name', 'Studio name', req: true), F('state', 'Status', o: ['Available', 'On air', 'Upcoming', 'Maintenance']), F('prog', 'Current / next program'), F('who', 'Current anchor'), F('time', 'Time slot'), F('cap', 'Capacity (people)', num: true), F('equip', 'Equipment')], ['Available', 'On air', 'Upcoming', 'Maintenance']),
};

List<String>? optsFor(F f) {
  if (f.o != null) return f.o;
  switch (f.k) {
    case 'anchor':
      return store.names('anchors');
    case 'studio':
      return store.names('studios');
    case 'cameraman':
      return ['Unassigned', ...store.names('cams')];
    case 'editor':
      return ['Unassigned', ...store.names('eds')];
    case 'driver':
      return ['Unassigned', 'Not required', ...store.names('drivers')];
  }
  return null;
}

// ───────────────────────── Store ─────────────────────────
final store = Store();
final nav = ValueNotifier<int>(0);

class Store extends ChangeNotifier {
  late SharedPreferences sp;
  M d = {};
  List<M> l(String k) => (d[k] as List).cast<M>();
  List<String> names(String k) => l(k).map((e) => '${e['name']}').toList();

  Future<void> init() async {
    sp = await SharedPreferences.getInstance();
    final s = sp.getString('99tv_flutter_v1');
    if (s != null) {
      try {
        d = Map<String, dynamic>.from(jsonDecode(s) as Map);
      } catch (_) {}
    }
    if (d['studios'] == null) d = seed();
  }

  void persist() {
    sp.setString('99tv_flutter_v1', jsonEncode(d));
    notifyListeners();
  }

  void reset() {
    d = seed();
    persist();
  }

  List<M> mk(List<List<dynamic>> r, List<String> k, String p) => [
        for (var i = 0; i < r.length; i++) <String, dynamic>{'id': '$p${i + 1}', for (var j = 0; j < k.length; j++) k[j]: r[i][j]}
      ];

  M seed() => <String, dynamic>{
        'studios': mk([
          ['Studio 01', 'On air', 'Morning News', 'Anjali Sharma', '09:00–10:00', 80, 12, '4 cameras · Teleprompter · LED wall'],
          ['Studio 02', 'Available', 'No active show', '—', 'Next · 11:00', 0, 8, '3 cameras · Green screen'],
          ['Studio 03', 'Upcoming', 'Sports Bulletin', 'Sana Ali', '10:30–11:00', 0, 10, '3 cameras · Virtual set'],
          ['Studio 04', 'Maintenance', 'Unavailable', '—', 'Lighting service', 0, 6, '2 cameras · Lighting grid'],
        ], ['name', 'state', 'prog', 'who', 'time', 'pct', 'cap', 'equip'], 'ST'),
        'anchors': mk([
          ['Anjali Sharma', 'Senior Anchor', 3, 'On air'],
          ['Priya Menon', 'News Anchor', 2, 'Assigned'],
          ['Rohit Verma', 'Lead Anchor', 2, 'Available'],
          ['Neha Kapoor', 'News Anchor', 1, 'Available'],
          ['Sana Ali', 'Business Anchor', 2, 'Assigned'],
          ['Vikram Rao', 'Senior Anchor', 3, 'Assigned'],
          ['Rahul Mehta', 'Sports Anchor', 0, 'Off duty'],
          ['Meera Das', 'News Anchor', 1, 'Available'],
        ], ['name', 'role', 'shows', 'status'], 'AN'),
        'drivers': mk([
          ['Ramesh Kumar', 'TS 09 AB 1234', 'Jubilee Hills', 5, 'Available'],
          ['Arjun Rao', 'TS 10 CD 5678', 'Banjara Hills', 4, 'On road'],
          ['Ravi Kumar', 'TS 08 EF 9012', 'Madhapur', 6, 'On road'],
          ['Imran Khan', 'TS 11 GH 3456', 'Gachibowli', 3, 'Available'],
          ['Suresh Reddy', 'TS 07 JK 7890', '—', 0, 'Off duty'],
        ], ['name', 'vehicle', 'location', 'trips', 'status'], 'DR'),
        'cams': mk([
          ['Sandeep Raju', 'Studio Camera', '06:00–14:00', 'Available'],
          ['Nikhil Varma', 'Field Camera', '09:00–18:00', 'Assigned'],
          ['Farhan Ali', 'PTZ Camera', '12:00–20:00', 'Off duty'],
          ['Lakshmi Devi', 'ENG News Camera', '08:00–16:00', 'Available'],
        ], ['name', 'specialty', 'shift', 'status'], 'CM'),
        'eds': mk([
          ['Keerthi Rao', 'Video Editor', 'City Focus', 'Available'],
          ['Manoj Kumar', 'Senior Editor', 'Morning package', 'Editing'],
          ['Sonia Thomas', 'Graphics', 'Business Today', 'Assigned'],
        ], ['name', 'specialty', 'pkg', 'status'], 'ED'),
        'bookings': mk([
          ['Morning News', 'Studio 01', 'Anjali Sharma', '09:00', '10:00', 'On air'],
          ['Sports Bulletin', 'Studio 03', 'Sana Ali', '10:30', '11:00', 'Upcoming'],
          ['City Focus', 'Studio 01', 'Neha Kapoor', '10:30', '11:30', 'Scheduled'],
          ['Business Today', 'Studio 02', 'Rohit Verma', '11:00', '12:00', 'Scheduled'],
          ['Evening News', 'Studio 02', 'Priya Menon', '17:00', '18:00', 'Scheduled'],
        ], ['program', 'studio', 'anchor', 'start', 'end', 'status'], 'BK'),
        'assigns': mk([
          ['Morning Brief', '09:00–10:00', 'Studio 01', 'Neha Kapoor', 'Sandeep Raju', 'Keerthi Rao', 'Arjun Rao', 'Completed'],
          ['Newsroom Live', '10:00–11:00', 'Studio 01', 'Anjali Sharma', 'Sandeep Raju', 'Manoj Kumar', 'Not required', 'On air'],
          ['Midday Bulletin', '11:00–12:00', 'Studio 02', 'Priya Menon', 'Lakshmi Devi', 'Sonia Thomas', 'Ravi Kumar', 'Ready'],
          ['In Focus', '12:00–13:00', 'Studio 03', 'Sana Ali', 'Nikhil Varma', 'Keerthi Rao', 'Unassigned', 'Needs driver'],
          ['Evening News', '17:00–18:00', 'Studio 02', 'Priya Menon', 'Lakshmi Devi', 'Sonia Thomas', 'Ramesh Kumar', 'Scheduled'],
        ], ['program', 'time', 'studio', 'anchor', 'cameraman', 'editor', 'driver', 'status'], 'AS'),
        'set': <String, dynamic>{'ws': '99TV Broadcast Operations', 'buffer': 15, 'notif': true},
      };

  String? conflict(M b, {String? skip}) {
    for (final x in l('bookings')) {
      if (x['id'] == skip) continue;
      final sameS = x['studio'] == b['studio'], sameA = x['anchor'] == b['anchor'];
      if ((sameS || sameA) && '${b['start']}'.compareTo('${x['end']}') < 0 && '${b['end']}'.compareTo('${x['start']}') > 0) {
        return '${x['program']} (${x['start']}–${x['end']}) already uses ${sameS ? x['studio'] : x['anchor']}.';
      }
    }
    return null;
  }

  String? save(String k, M v, [String? id]) {
    if (k == 'bookings') {
      if ('${v['end']}'.compareTo('${v['start']}') <= 0) return 'End time must be after start time.';
      final s = l('studios').firstWhere((s) => s['name'] == v['studio'], orElse: () => <String, dynamic>{});
      if (s['state'] == 'Maintenance') return '${v['studio']} is under maintenance.';
      final c = conflict(v, skip: id);
      if (c != null) return 'Conflict: $c';
    }
    final list = d[k] as List;
    if (id != null) {
      final i = list.indexWhere((x) => x['id'] == id);
      if (i >= 0) list[i] = <String, dynamic>{...(list[i] as Map<String, dynamic>), ...v};
    } else {
      final extra = k == 'studios' ? <String, dynamic>{'pct': 0} : <String, dynamic>{};
      list.add(<String, dynamic>{'id': '${k.substring(0, 2).toUpperCase()}${DateTime.now().millisecondsSinceEpoch % 100000}', ...extra, ...v});
    }
    persist();
    return null;
  }

  void remove(String k, String id) {
    (d[k] as List).removeWhere((x) => x['id'] == id);
    persist();
  }

  void cycle(String k, M r) {
    final key = k == 'studios' ? 'state' : 'status', o = cfgs[k]!.st;
    r[key] = o[(o.indexOf('${r[key]}') + 1) % o.length];
    if (k == 'studios') r['pct'] = r[key] == 'On air' ? 40 : 0;
    persist();
  }

  bool get notifOn => (d['set'] as Map?)?['notif'] != false;

  List<(String, int)> alerts() => [
        for (final a in l('assigns')) if (a['driver'] == 'Unassigned' && a['status'] != 'Completed') ('Driver needed: ${a['program']} · ${a['anchor']}', 7),
        for (final s in l('studios')) if (s['state'] == 'Maintenance') ('${s['name']} is under maintenance', 1),
        for (final s in l('studios')) if (s['state'] == 'On air') ('${s['name']} is live: ${s['prog']}', 2),
      ];
}

// ───────────────────────── Helpers ─────────────────────────
double tm(String t) {
  final p = t.split(':');
  return int.parse(p[0]) + int.parse(p[1]) / 60;
}

String ini(String n) => n.split(' ').where((e) => e.isNotEmpty).map((e) => e[0]).take(2).join().toUpperCase();

(Color, Color) sc(String s) {
  final t = s.toLowerCase();
  if (t.contains('air') || t.contains('live')) return (const Color(0xFFFFEAED), const Color(0xFFC51B31));
  if (RegExp('need|maint|unassigned').hasMatch(t)) return (const Color(0xFFFFE3E6), const Color(0xFFB4172B));
  if (RegExp('complet|avail|ready|good').hasMatch(t)) return (const Color(0xFFE4F6EE), const Color(0xFF12805B));
  if (t.contains('off')) return (const Color(0xFFEEF0F4), const Color(0xFF636C7B));
  return (const Color(0xFFFFF3DF), const Color(0xFF9B6818));
}

void snack(BuildContext c, String m) => ScaffoldMessenger.of(c)
  ..clearSnackBars()
  ..showSnackBar(SnackBar(content: Text(m, style: const TextStyle(fontWeight: FontWeight.w700)), behavior: SnackBarBehavior.floating, backgroundColor: ink, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));

Widget chip(String s) {
  final c = sc(s);
  return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: c.$1, borderRadius: BorderRadius.circular(20)), child: Text(s, style: TextStyle(color: c.$2, fontSize: 10.5, fontWeight: FontWeight.w800)));
}

Widget avatar(String n, {double s = 38}) => Container(
    width: s,
    height: s,
    alignment: Alignment.center,
    decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFFD9DE), Color(0xFFF19AA5)]), borderRadius: BorderRadius.circular(s * .3)),
    child: Text(ini(n), style: TextStyle(color: const Color(0xFF8C1728), fontWeight: FontWeight.w800, fontSize: s * .32)));

// Box with a coloured left accent edge (a non-uniform Border can't be combined with borderRadius).
Widget accentBox({required Color edge, required Widget child, Color? bg, Gradient? grad, List<BoxShadow>? shadow, double r = 10}) => Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: bg, gradient: grad, borderRadius: BorderRadius.circular(r), boxShadow: shadow),
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(width: 4, color: edge),
        Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: child)),
      ]),
    );

class Cardx extends StatelessWidget {
  final Widget child;
  final EdgeInsets pad;
  final VoidCallback? onTap;
  final Color? color;
  final Gradient? grad;
  const Cardx({super.key, required this.child, this.pad = const EdgeInsets.all(18), this.onTap, this.color, this.grad});
  @override
  Widget build(BuildContext c) => Container(
        decoration: BoxDecoration(color: grad == null ? (color ?? Colors.white) : null, gradient: grad, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE9ECF2)), boxShadow: const [BoxShadow(color: Color(0x0F182238), blurRadius: 24, offset: Offset(0, 8))]),
        child: Material(color: Colors.transparent, borderRadius: BorderRadius.circular(18), clipBehavior: Clip.antiAlias, child: InkWell(onTap: onTap, child: Padding(padding: pad, child: child))),
      );
}

class Grid extends StatelessWidget {
  final List<Widget> ch;
  final int max, phone;
  final double gap;
  const Grid(this.ch, {super.key, this.max = 4, this.phone = 2, this.gap = 14});
  @override
  Widget build(BuildContext c) => LayoutBuilder(builder: (c, b) {
        final n = b.maxWidth > 1000 ? max : b.maxWidth > 600 ? (max > 2 ? 2 : max) : phone;
        final w = (b.maxWidth - gap * (n - 1)) / n - .01;
        return Wrap(spacing: gap, runSpacing: gap, children: [for (final x in ch) SizedBox(width: w, child: x)]);
      });
}

Widget stat(String l, String v, String sub, IconData i, {int? go}) => Cardx(
      onTap: go == null ? null : () => nav.value = go,
      child: Row(children: [
        Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l, style: const TextStyle(color: mut, fontSize: 11.5, fontWeight: FontWeight.w700)),
          FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(v, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -1.5, color: tx))),
          Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: mut, fontSize: 10.5)),
        ])),
        Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFFFFF0F2), borderRadius: BorderRadius.circular(12)), child: Icon(i, color: red, size: 20)),
      ]),
    );

Widget head(String t, String s, List<Widget> a) => Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Wrap(spacing: 12, runSpacing: 12, alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.end, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(t, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -1, color: tx)),
          Text(s, style: const TextStyle(color: mut, fontSize: 12.5)),
        ]),
        Wrap(spacing: 8, runSpacing: 8, children: a),
      ]),
    );

Widget pbtn(String l, VoidCallback f, {IconData? i}) => FilledButton.icon(onPressed: f, icon: Icon(i ?? Icons.add_rounded, size: 18), label: Text(l), style: FilledButton.styleFrom(backgroundColor: red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)));
Widget obtn(String l, VoidCallback f, {IconData? i}) => OutlinedButton.icon(onPressed: f, icon: Icon(i ?? Icons.file_download_outlined, size: 18), label: Text(l), style: OutlinedButton.styleFrom(foregroundColor: tx, side: const BorderSide(color: Color(0xFFE1E5EC)), backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)));
Widget title(String t, [String? s]) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: tx)), if (s != null) Text(s, style: const TextStyle(color: mut, fontSize: 11))]);

void copyCsv(BuildContext c, String k) {
  final rows = store.l(k);
  if (rows.isEmpty) return snack(c, 'No data to export.');
  final keys = rows.first.keys.toList();
  final table = <List<dynamic>>[keys, ...rows.map((r) => keys.map((x) => r[x]).toList())];
  final t = table.map((r) => r.map((v) => '"${'$v'.replaceAll('"', '""')}"').join(',')).join('\n');
  Clipboard.setData(ClipboardData(text: t));
  snack(c, 'CSV copied to clipboard (${rows.length} rows).');
}

Future<bool> confirm(BuildContext c, String m, [String ok = 'Delete']) async =>
    await showDialog<bool>(context: c, builder: (c) => AlertDialog(title: const Text('Please confirm'), content: Text(m), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')), FilledButton(style: FilledButton.styleFrom(backgroundColor: red), onPressed: () => Navigator.pop(c, true), child: Text(ok))])) ?? false;

Future<void> formDlg(BuildContext c, String k, {M? rec, M pre = const {}}) async {
  final cf = cfgs[k]!, v = <String, dynamic>{...pre, ...?rec}, key = GlobalKey<FormState>();
  String? error;
  for (final f in cf.f) {
    final o = optsFor(f);
    if (o != null && o.isNotEmpty && !o.contains(v[f.k])) v[f.k] = o.first;
  }
  await showDialog(
      context: c,
      builder: (dc) => StatefulBuilder(
          builder: (dc, setS) => AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: Text('${rec == null ? 'Add' : 'Edit'} ${cf.one.toLowerCase()}', style: const TextStyle(fontWeight: FontWeight.w800)),
                content: SizedBox(
                    width: 440,
                    child: Form(
                        key: key,
                        child: SingleChildScrollView(
                            child: Column(mainAxisSize: MainAxisSize.min, children: [
                          for (final f in cf.f)
                            Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: optsFor(f) != null
                                    ? DropdownButtonFormField<String>(initialValue: v[f.k] as String?, isExpanded: true, decoration: InputDecoration(labelText: f.l), items: [for (final o in optsFor(f)!) DropdownMenuItem(value: o, child: Text(o))], onChanged: (x) => v[f.k] = x)
                                    : TextFormField(
                                        initialValue: '${v[f.k] ?? ''}',
                                        decoration: InputDecoration(labelText: f.l),
                                        keyboardType: f.num ? TextInputType.number : TextInputType.text,
                                        validator: (x) {
                                          if (f.req && (x ?? '').trim().isEmpty) return 'Required';
                                          if (f.time && !RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(x ?? '')) return 'Use HH:MM';
                                          if (f.num && int.tryParse(x ?? '') == null) return 'Enter a number';
                                          return null;
                                        },
                                        onChanged: (x) => v[f.k] = x)),
                          if (error != null) Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFFFE3E6), borderRadius: BorderRadius.circular(12)), child: Text(error!, style: const TextStyle(color: Color(0xFFB4172B), fontWeight: FontWeight.w700, fontSize: 12.5))),
                        ])))),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(dc), child: const Text('Cancel')),
                  FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: red),
                      onPressed: () {
                        if (!key.currentState!.validate()) return;
                        for (final f in cf.f) {
                          if (f.num) v[f.k] = int.tryParse('${v[f.k]}') ?? 0;
                        }
                        final err = store.save(k, v, rec?['id'] as String?);
                        if (err != null) {
                          setS(() => error = err);
                          return;
                        }
                        Navigator.pop(dc);
                        snack(c, rec == null ? 'Record added.' : 'Changes saved.');
                      },
                      child: const Text('Save')),
                ],
              )));
}

// ───────────────────────── Timeline ─────────────────────────
class Timeline extends StatelessWidget {
  const Timeline({super.key});
  @override
  Widget build(BuildContext c) {
    const tw = 840.0, lw = 124.0, st = 8.0, sp = 10.0, now = 10.25;
    double x(double h) => (h - st) / sp * tw;
    final bk = store.l('bookings');
    return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(16),
        child: SizedBox(
            width: lw + tw,
            child: Stack(children: [
              Column(children: [
                SizedBox(
                    height: 26,
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const SizedBox(width: lw),
                      for (var h = 8; h < 18; h++) SizedBox(width: tw / 10, child: Text('${h.toString().padLeft(2, '0')}:00', style: const TextStyle(fontSize: 10, color: mut, fontWeight: FontWeight.w700)))
                    ])),
                for (final s in store.l('studios'))
                  SizedBox(
                      height: 64,
                      child: Row(children: [
                        SizedBox(
                            width: lw,
                            child: Row(children: [
                              Container(width: 9, height: 9, decoration: BoxDecoration(shape: BoxShape.circle, color: s['state'] == 'On air' ? red : s['state'] == 'Available' ? const Color(0xFF15966B) : s['state'] == 'Upcoming' ? const Color(0xFFE0A23A) : const Color(0xFFC3C9D4))),
                              const SizedBox(width: 9),
                              Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${s['name']}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)), Text('${s['state']}', style: const TextStyle(fontSize: 10, color: mut))]),
                            ])),
                        SizedBox(
                            width: tw,
                            child: Stack(children: [
                              Positioned.fill(child: Container(margin: const EdgeInsets.symmetric(vertical: 3), decoration: BoxDecoration(color: const Color(0xFFF8F9FB), borderRadius: BorderRadius.circular(12)))),
                              for (var i = 1; i < 10; i++) Positioned(left: i * tw / 10, top: 3, bottom: 3, child: Container(width: 1, color: const Color(0xFFE9ECF2))),
                              if (s['state'] == 'Maintenance')
                                Positioned(left: 4, right: 4, top: 9, bottom: 9, child: accentBox(edge: const Color(0xFFAEB5C2), bg: const Color(0xFFECEEF2), child: const Align(alignment: Alignment.centerLeft, child: Text('Maintenance window', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: mut))))),
                              for (final b in bk.where((b) => b['studio'] == s['name']))
                                () {
                                  final left = x(tm('${b['start']}')).clamp(0.0, tw).toDouble();
                                  final w = (x(tm('${b['end']}')) - left).clamp(30.0, tw - left).toDouble();
                                  final a = b['status'] == 'On air', d = b['status'] == 'Completed';
                                  return Positioned(
                                      left: left + 2,
                                      top: 9,
                                      height: 46,
                                      width: w - 4,
                                      child: GestureDetector(
                                        onTap: () => snack(c, '${b['program']} · ${b['studio']} · ${b['start']}–${b['end']} · ${b['anchor']}'),
                                        child: accentBox(
                                            edge: a ? const Color(0xFF8C0F1F) : d ? const Color(0xFF27A979) : const Color(0xFF5B8FD4),
                                            grad: a ? const LinearGradient(colors: [Color(0xFFE11D35), Color(0xFFF0495C)]) : null,
                                            bg: a ? null : d ? const Color(0xFFE8F6EF) : const Color(0xFFEAF1FC),
                                            shadow: a ? const [BoxShadow(color: Color(0x44E11D35), blurRadius: 14, offset: Offset(0, 6))] : null,
                                            child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                                              Text('${b['program']}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: a ? Colors.white : d ? const Color(0xFF17684B) : const Color(0xFF2B4D7D))),
                                              Text('${b['start']} – ${b['end']}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 9.5, color: a ? Colors.white70 : mut)),
                                            ])),
                                      ));
                                }(),
                            ])),
                      ])),
              ]),
              Positioned(left: lw + x(now), top: 22, bottom: 0, child: Container(width: 2, color: red)),
              Positioned(left: lw + x(now) - 28, top: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2), decoration: BoxDecoration(color: red, borderRadius: BorderRadius.circular(9)), child: const Text('Now 10:15', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)))),
            ])));
  }
}

// ───────────────────────── Studios ─────────────────────────
Widget studioCard(BuildContext c, M s, int i) {
  const g = [
    [Color(0xFF222B3A), Color(0xFF39465B)],
    [Color(0xFF273748), Color(0xFF43546A)],
    [Color(0xFF392E35), Color(0xFF61454B)],
    [Color(0xFF303640), Color(0xFF414751)]
  ];
  final live = s['state'] == 'On air';
  final pct = ((s['pct'] as num?) ?? 0).toDouble();
  return Cardx(
      pad: EdgeInsets.zero,
      onTap: () => studioSheet(c, s),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
            height: 112,
            decoration: BoxDecoration(gradient: LinearGradient(colors: g[i % 4], begin: Alignment.topLeft, end: Alignment.bottomRight)),
            child: Stack(children: [
              Positioned(right: -30, top: -50, child: Container(width: 140, height: 140, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x2BE11D35)))),
              Center(child: Text('${s['name']}'.replaceAll('Studio ', ''), style: const TextStyle(color: Colors.white, fontSize: 46, fontWeight: FontWeight.w800, letterSpacing: -3))),
              Positioned(top: 12, right: 12, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: Row(mainAxisSize: MainAxisSize.min, children: [if (live) const Icon(Icons.circle, size: 8, color: red), if (live) const SizedBox(width: 4), Text(live ? 'LIVE' : '${s['state']}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: live ? red : tx))]))),
            ])),
        Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${s['name']}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              Text('${s['prog']}', style: const TextStyle(color: mut, fontSize: 11.5)),
              const SizedBox(height: 10),
              ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: pct / 100, minHeight: 6, color: red, backgroundColor: const Color(0xFFEDF0F4))),
              const SizedBox(height: 8),
              Text('${s['who']} · ${s['time']}', style: const TextStyle(color: mut, fontSize: 10.5)),
            ])),
      ]));
}

void studioSheet(BuildContext c, M s) {
  showModalBottomSheet(
      context: c,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      builder: (sheet) => AnimatedBuilder(
          animation: store,
          builder: (_, __) {
            final bk = store.l('bookings').where((b) => b['studio'] == s['name']).toList(), maint = s['state'] == 'Maintenance';
            return SafeArea(
                child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      Row(children: [Text('${s['name']}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -.8)), const SizedBox(width: 10), chip('${s['state']}')]),
                      const SizedBox(height: 6),
                      Text('${s['prog']} · ${s['who']} · ${s['time']}', style: const TextStyle(color: mut)),
                      const SizedBox(height: 14),
                      Wrap(spacing: 10, runSpacing: 10, children: [
                        for (final e in [('Capacity', '${s['cap']} people'), ('Equipment', '${s['equip']}'), ('Bookings today', '${bk.length}')])
                          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: bgc, borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(e.$1, style: const TextStyle(fontSize: 10, color: mut, fontWeight: FontWeight.w700)), Text(e.$2, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12))]))
                      ]),
                      const SizedBox(height: 16),
                      const Text('Today\'s bookings', style: TextStyle(fontWeight: FontWeight.w800)),
                      if (bk.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Text('No bookings yet for this studio.', style: TextStyle(color: mut))),
                      for (final b in bk) ListTile(contentPadding: EdgeInsets.zero, title: Text('${b['program']}', style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text('${b['start']}–${b['end']} · ${b['anchor']}'), trailing: chip('${b['status']}')),
                      const SizedBox(height: 14),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        pbtn('Book studio', () {
                          if (maint) return snack(sheet, '${s['name']} is under maintenance.');
                          Navigator.pop(sheet);
                          formDlg(c, 'bookings', pre: {'studio': s['name'], 'status': 'Scheduled', 'start': '13:00', 'end': '14:00'});
                        }, i: Icons.event_available_rounded),
                        obtn('Change status', () => store.cycle('studios', s), i: Icons.sync_rounded),
                        obtn('Edit', () {
                          Navigator.pop(sheet);
                          formDlg(c, 'studios', rec: s);
                        }, i: Icons.edit_rounded),
                        obtn('Delete', () async {
                          if (await confirm(sheet, 'Delete ${s['name']}?')) {
                            store.remove('studios', s['id'] as String);
                            if (sheet.mounted) Navigator.pop(sheet);
                          }
                        }, i: Icons.delete_outline_rounded),
                      ]),
                    ])));
          }));
}

class StudiosPage extends StatelessWidget {
  const StudiosPage({super.key});
  @override
  Widget build(BuildContext c) {
    final st = store.l('studios');
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      head('Studio Management', 'Live studio overview, availability and bookings.', [pbtn('Add studio', () => formDlg(c, 'studios')), pbtn('Book studio', () => formDlg(c, 'bookings', pre: {'status': 'Scheduled', 'start': '13:00', 'end': '14:00'}), i: Icons.event_available_rounded)]),
      Grid([for (var i = 0; i < st.length; i++) studioCard(c, st[i], i)], max: 4, phone: 1),
      const SizedBox(height: 20),
      Roster('bookings', embed: true),
    ]);
  }
}

// ───────────────────────── Roster (generic CRUD) ─────────────────────────
class Roster extends StatefulWidget {
  final String coll;
  final bool embed;
  const Roster(this.coll, {super.key, this.embed = false});
  @override
  State<Roster> createState() => _R();
}

class _R extends State<Roster> {
  String q = '', f = '';
  @override
  Widget build(BuildContext c) {
    final k = widget.coll, cf = cfgs[k]!, all = store.l(k), st = cf.st;
    final rows = all.where((r) => (q.isEmpty || r.values.join(' ').toLowerCase().contains(q)) && (f.isEmpty || r['status'] == f)).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (!widget.embed) ...[
        head(cf.title, 'Search, filter and update ${cf.one.toLowerCase()} records.', [obtn('Copy CSV', () => copyCsv(c, k)), pbtn('Add ${cf.one.toLowerCase()}', () => formDlg(c, k, pre: k == 'assigns' ? {'driver': 'Unassigned', 'status': 'Scheduled'} : {}))]),
        Grid([stat('Total', '${all.length}', 'Records', Icons.groups_rounded), for (final s in st.take(3)) stat(s, '${all.where((r) => r['status'] == s).length}', 'Current', Icons.circle)], max: 4),
        const SizedBox(height: 18),
      ] else
        Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [Expanded(child: title('Booking history', 'Overlapping studio or anchor bookings are blocked')), obtn('CSV', () => copyCsv(c, k)), const SizedBox(width: 8), pbtn('Add', () => formDlg(c, k, pre: {'status': 'Scheduled', 'start': '13:00', 'end': '14:00'}))])),
      Row(children: [
        Expanded(child: TextField(onChanged: (x) => setState(() => q = x.toLowerCase()), decoration: const InputDecoration(hintText: 'Search…', prefixIcon: Icon(Icons.search_rounded)))),
        const SizedBox(width: 10),
        SizedBox(width: 160, child: DropdownButtonFormField<String>(initialValue: f, isExpanded: true, items: [const DropdownMenuItem(value: '', child: Text('All statuses')), for (final s in st) DropdownMenuItem(value: s, child: Text(s))], onChanged: (x) => setState(() => f = x ?? ''))),
      ]),
      const SizedBox(height: 12),
      if (rows.isEmpty) const Cardx(child: Center(child: Padding(padding: EdgeInsets.all(18), child: Text('No records match. Use the add button to create one.', style: TextStyle(color: mut))))),
      for (final r in rows)
        Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Cardx(
                pad: const EdgeInsets.all(14),
                child: Row(children: [
                  avatar('${r[cf.cols[0]]}'),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${r[cf.cols[0]]}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                    Text(cf.cols.skip(1).map((x) => '${r[x]}').join('  ·  '), style: const TextStyle(color: mut, fontSize: 11.5)),
                    if (r.values.contains('Unassigned')) const Padding(padding: EdgeInsets.only(top: 4), child: Row(children: [Icon(Icons.warning_amber_rounded, size: 14, color: red), SizedBox(width: 4), Text('Missing staff', style: TextStyle(color: red, fontSize: 10.5, fontWeight: FontWeight.w800))])),
                  ])),
                  if (r['status'] != null) chip('${r['status']}'),
                  PopupMenuButton<String>(
                      onSelected: (a) async {
                        if (a == 'edit') formDlg(c, k, rec: r);
                        if (a == 'cycle') {
                          store.cycle(k, r);
                          snack(c, 'Status: ${r['status']}');
                        }
                        if (a == 'del' && await confirm(c, 'Remove this record?')) store.remove(k, r['id'] as String);
                      },
                      itemBuilder: (_) => [
                            const PopupMenuItem(value: 'edit', child: Text('Edit')),
                            if (r['status'] != null) PopupMenuItem(value: 'cycle', child: Text(k == 'assigns' ? 'Advance workflow' : 'Next status')),
                            const PopupMenuItem(value: 'del', child: Text('Delete', style: TextStyle(color: red))),
                          ]),
                ]))),
    ]);
  }
}

// ───────────────────────── Dashboard / Schedule ─────────────────────────
class Dashboard extends StatelessWidget {
  const Dashboard({super.key});
  @override
  Widget build(BuildContext c) {
    final need = store.l('assigns').where((a) => a['driver'] == 'Unassigned' && a['status'] != 'Completed').toList();
    final st = store.l('studios'), bk = [...store.l('bookings')]..sort((a, b) => '${a['start']}'.compareTo('${b['start']}'));
    int n(String k, String s) => store.l(k).where((r) => r['status'] == s).length;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      head('Dashboard', 'Your newsroom, in sync. Today\'s people, studios and broadcasts.', [pbtn('New assignment', () => formDlg(c, 'assigns', pre: {'driver': 'Unassigned', 'status': 'Scheduled'})), obtn('Book studio', () => formDlg(c, 'bookings', pre: {'status': 'Scheduled', 'start': '13:00', 'end': '14:00'}), i: Icons.event_available_rounded)]),
      Grid([
        stat('Studios', '${st.length}', '${st.where((s) => s['state'] == 'On air').length} on air · ${st.where((s) => s['state'] == 'Available').length} free · ${st.where((s) => s['state'] == 'Maintenance').length} maintenance', Icons.live_tv_rounded, go: 1),
        stat('Anchors', '${store.l('anchors').length}', '${n('anchors', 'Available')} available', Icons.mic_rounded, go: 3),
        stat('Drivers', '${store.l('drivers').length}', '${n('drivers', 'Available')} available', Icons.local_taxi_rounded, go: 4),
        stat('Cameramen', '${store.l('cams').length}', '${n('cams', 'Available')} available', Icons.videocam_rounded, go: 5),
        stat('Production', '${store.l('eds').length}', '${n('eds', 'Editing')} editing', Icons.content_cut_rounded, go: 6),
        stat('Assignments', '${store.l('assigns').length}', '${need.length} need attention', Icons.assignment_rounded, go: 7),
      ], max: 3),
      const SizedBox(height: 16),
      if (need.isNotEmpty)
        Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFFFFF5E6), border: Border.all(color: const Color(0xFFF2DFBD)), borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFF9B6818)),
              const SizedBox(width: 10),
              Expanded(child: Text('${need.length} assignment needs a driver: ${need.first['program']} · ${need.first['anchor']}', style: const TextStyle(color: Color(0xFF805B1E), fontWeight: FontWeight.w700))),
              TextButton(
                  onPressed: () {
                    final dr = store.l('drivers').where((d) => d['status'] == 'Available').toList();
                    if (dr.isEmpty) return snack(c, 'No available drivers right now.');
                    need.first['driver'] = dr.first['name'];
                    need.first['status'] = 'Scheduled';
                    store.persist();
                    snack(c, '${dr.first['name']} assigned to ${need.first['program']}.');
                  },
                  child: const Text('Assign driver', style: TextStyle(color: red, fontWeight: FontWeight.w800))),
            ])),
      Grid([for (var i = 0; i < st.length; i++) studioCard(c, st[i], i)], max: 4, phone: 1),
      const SizedBox(height: 16),
      Cardx(
          pad: EdgeInsets.zero,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(padding: const EdgeInsets.fromLTRB(18, 18, 18, 0), child: Row(children: [Expanded(child: title('Studio timeline', 'Tap any block for details · built from live bookings')), TextButton(onPressed: () => nav.value = 2, child: const Text('Full schedule'))])),
            Timeline(),
          ])),
      const SizedBox(height: 16),
      Cardx(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        title('Upcoming broadcasts'),
        const SizedBox(height: 8),
        for (final b in bk.take(5)) ListTile(contentPadding: EdgeInsets.zero, leading: avatar('${b['anchor']}'), title: Text('${b['program']}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)), subtitle: Text('${b['start']}–${b['end']} · ${b['studio']} · ${b['anchor']}'), trailing: chip('${b['status']}')),
      ])),
    ]);
  }
}

class SchedulePage extends StatelessWidget {
  const SchedulePage({super.key});
  @override
  Widget build(BuildContext c) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        head('Studio Schedule', 'Plan bookings and avoid conflicts.', [obtn('Week view', () => snack(c, 'Week view: Mon 16 – Sun 22 Nov'), i: Icons.calendar_view_week_rounded), pbtn('Book studio', () => formDlg(c, 'bookings', pre: {'status': 'Scheduled', 'start': '13:00', 'end': '14:00'}), i: Icons.event_available_rounded)]),
        Cardx(pad: EdgeInsets.zero, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Padding(padding: const EdgeInsets.fromLTRB(18, 18, 18, 0), child: title('Broadcast calendar', 'Thursday, 19 November 2026 · IST')), Timeline()])),
        const SizedBox(height: 20),
        Roster('bookings', embed: true),
      ]);
}

// ───────────────────────── Reports ─────────────────────────
class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});
  @override
  State<ReportsPage> createState() => _Rp();
}

class _Rp extends State<ReportsPage> {
  int t = 0;
  void _open(BuildContext c, String name) {
    for (final a in store.l('anchors')) {
      if (a['name'] == name) {
        perfSheet(c, a);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext c) {
    final bk = store.l('bookings'), asg = store.l('assigns');
    final data = <List<(String, int)>>[
      [for (final s in store.l('studios')) ('${s['name']}', (bk.where((b) => b['studio'] == s['name']).fold<double>(0, (a, b) => a + tm('${b['end']}') - tm('${b['start']}')) / 10 * 100).round().clamp(0, 100).toInt())],
      [for (final a in store.l('anchors')) ('${a['name']}', (((a['shows'] as num?) ?? 0) / 4 * 100).round().clamp(0, 100).toInt())],
      [for (final d in store.l('drivers')) ('${d['name']}', (((d['trips'] as num?) ?? 0) / 8 * 100).round().clamp(0, 100).toInt())],
      [for (final s in cfgs['assigns']!.st) (s, asg.isEmpty ? 0 : (asg.where((a) => a['status'] == s).length / asg.length * 100).round())],
    ][t];
    final done = asg.isEmpty ? 0 : (asg.where((a) => a['status'] == 'Completed').length / asg.length * 100).round();
    final tabs = ['Studio', 'Anchors', 'Drivers', 'Assignments'];
    final usage = (data.isEmpty || t != 0) ? 84 : (data.map((e) => e.$2).reduce((a, b) => a + b) / data.length).round();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      head('Reports & Analytics', 'Calculated live from your current data.', [
        obtn(t == 1 ? 'Export full CSV' : 'Copy CSV', () {
          if (t == 1) return exportAnchors(c);
          final csv = 'Label,Percent\n${data.map((e) => '"${e.$1}",${e.$2}').join('\n')}';
          Clipboard.setData(ClipboardData(text: csv));
          snack(c, 'Report CSV copied.');
        })
      ]),
      SingleChildScrollView(scrollDirection: Axis.horizontal, child: SegmentedButton<int>(showSelectedIcon: false, style: SegmentedButton.styleFrom(selectedBackgroundColor: ink, selectedForegroundColor: Colors.white, backgroundColor: Colors.white), segments: [for (var i = 0; i < 4; i++) ButtonSegment<int>(value: i, label: Text(tabs[i]))], selected: {t}, onSelectionChanged: (s) => setState(() => t = s.first))),
      const SizedBox(height: 16),
      Grid([stat('Programs', '${bk.length}', 'Booked today', Icons.tv_rounded), stat('Completion', '$done%', 'Assignments done', Icons.check_circle_outline_rounded), stat('Studio usage', '$usage%', 'Average utilisation', Icons.live_tv_rounded), stat('Needs attention', '${store.alerts().where((a) => a.$2 == 7).length}', 'Missing staff', Icons.warning_amber_rounded)]),
      const SizedBox(height: 16),
      Cardx(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        title('${tabs[t]} performance', t == 1 ? 'Tap an anchor to see the tangibles behind the score' : 'Percent of capacity or share'),
        const SizedBox(height: 12),
        for (final e in data)
          InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: t == 1 ? () => _open(c, e.$1) : null,
              child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Row(children: [
                SizedBox(width: 110, child: Text(e.$1, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(8), child: TweenAnimationBuilder<double>(tween: Tween<double>(begin: 0, end: e.$2 / 100), duration: const Duration(milliseconds: 600), builder: (_, v, __) => LinearProgressIndicator(value: v, minHeight: 9, color: red, backgroundColor: const Color(0xFFEDF0F4))))),
                SizedBox(width: 44, child: Text('${e.$2}%', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12))),
                if (t == 1) const Icon(Icons.chevron_right_rounded, size: 18, color: mut),
              ]))),
      ])),
    ]);
  }
}

// ───────────────────────── Settings / Help ─────────────────────────
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _Se();
}

class _Se extends State<SettingsPage> {
  late final M s = Map<String, dynamic>.from(store.d['set'] as Map);
  late final tc = TextEditingController(text: '${s['ws']}');
  @override
  void dispose() {
    tc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext c) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        head('Settings', 'Workspace and notification preferences.', [
          obtn('Reset demo data', () async {
            if (await confirm(c, 'Reset all data to the sample set?', 'Reset')) {
              store.reset();
              if (!mounted) return;
              setState(() {
                s
                  ..clear()
                  ..addAll(Map<String, dynamic>.from(store.d['set'] as Map));
                tc.text = '${s['ws']}';
              });
              snack(context, 'Data reset.');
            }
          }, i: Icons.restart_alt_rounded)
        ]),
        Cardx(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextField(controller: tc, decoration: const InputDecoration(labelText: 'Workspace name')),
          const SizedBox(height: 18),
          Text('Studio setup buffer: ${s['buffer']} min', style: const TextStyle(fontWeight: FontWeight.w700)),
          Slider(value: (s['buffer'] as num).toDouble(), min: 0, max: 60, divisions: 12, activeColor: red, onChanged: (v) => setState(() => s['buffer'] = v.round())),
          SwitchListTile(contentPadding: EdgeInsets.zero, activeThumbColor: red, title: const Text('In-app notifications'), subtitle: const Text('Alerts for missing staff and studio status'), value: s['notif'] == true, onChanged: (v) => setState(() => s['notif'] = v)),
          const SizedBox(height: 8),
          pbtn('Save settings', () {
            s['ws'] = tc.text;
            store.d['set'] = Map<String, dynamic>.from(s);
            store.persist();
            snack(c, 'Settings saved.');
          }, i: Icons.check_rounded),
        ])),
      ]);
}

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});
  @override
  Widget build(BuildContext c) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        head('Help & Support', 'How the 99TV workflow fits together.', [obtn('Contact support', () => snack(c, 'Support request sent to ops@99tv.in'), i: Icons.support_agent_rounded)]),
        Cardx(
            child: Column(children: [
          for (final q in [
            ('Booking workflow', 'Create a booking, pick an available studio and anchor, then assign a cameraman, editor and driver in Assignments. Move it Ready → On air → Completed with Advance workflow.'),
            ('Why was my booking rejected?', 'A studio or anchor cannot be in two bookings at once, and studios under maintenance cannot be booked. The message names the clashing show.'),
            ('How do I fix a missing driver?', 'Use Assign driver on the dashboard banner, or edit the assignment and choose a driver.'),
            ('Where is my data stored?', 'On this device. Use Copy CSV on any page to export it.'),
          ])
            ExpansionTile(title: Text(q.$1, style: const TextStyle(fontWeight: FontWeight.w700)), shape: const Border(), collapsedShape: const Border(), children: [Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 14), child: Align(alignment: Alignment.centerLeft, child: Text(q.$2, style: const TextStyle(color: mut))))]),
        ])),
      ]);
}

// ───────────────────────── Performance (tangibles behind the score) ─────────────────────────
class Perf {
  final M a;
  final List<M> bks, asg;
  final int shows, target, pct, done, live, crew, needDrv, asgDone;
  final double hours;
  final String grade;
  Perf._(this.a, this.bks, this.asg, this.shows, this.target, this.pct, this.done, this.live, this.crew, this.needDrv, this.asgDone, this.hours, this.grade);

  static bool full(M x) => x['cameraman'] != 'Unassigned' && x['editor'] != 'Unassigned' && x['driver'] != 'Unassigned';

  factory Perf(M a) {
    final n = '${a['name']}';
    const target = 4;
    final shows = ((a['shows'] as num?) ?? 0).toInt();
    final bks = store.l('bookings').where((b) => b['anchor'] == n).toList()..sort((x, y) => '${x['start']}'.compareTo('${y['start']}'));
    final asg = store.l('assigns').where((x) => x['anchor'] == n).toList()..sort((x, y) => '${x['time']}'.compareTo('${y['time']}'));
    final pct = (shows / target * 100).round().clamp(0, 100).toInt();
    final hours = bks.fold<double>(0, (s, b) => s + tm('${b['end']}') - tm('${b['start']}'));
    return Perf._(
        a,
        bks,
        asg,
        shows,
        target,
        pct,
        bks.where((b) => b['status'] == 'Completed').length,
        bks.where((b) => b['status'] == 'On air').length,
        asg.where(Perf.full).length,
        asg.where((x) => x['driver'] == 'Unassigned' && x['status'] != 'Completed').length,
        asg.where((x) => x['status'] == 'Completed').length,
        hours,
        pct >= 75 ? 'Excellent' : pct >= 50 ? 'On track' : pct > 0 ? 'Light load' : 'No shows');
  }

  String get name => '${a['name']}';

  String get verdict {
    if (shows == 0 && bks.isEmpty) return '$name has no shows logged today, so the score is 0%.';
    final b = StringBuffer('$name scores $pct% because $shows of the $target daily-target shows are logged, ${hours.toStringAsFixed(1)} h of airtime is booked across ${bks.length} booking(s), and $crew of ${asg.length} assignment(s) have a full crew.');
    if (needDrv > 0) b.write(' $needDrv assignment(s) still need a driver.');
    return b.toString();
  }

  // [metric, value, how it is calculated]
  List<List<String>> get basis => [
        ['Shows today', '$shows', 'Shows-today count on the anchor record'],
        ['Daily target', '$target', 'Standard load per anchor'],
        ['Performance score', '$pct%', '$shows ÷ $target × 100, capped at 100'],
        ['Grade', grade, '75%+ Excellent · 50–74% On track · 1–49% Light load · 0% No shows'],
        ['Studio bookings', '${bks.length}', 'Rows for this anchor in Studio Schedule'],
        ['Booked airtime', '${hours.toStringAsFixed(1)} h', 'Sum of (end − start) across bookings'],
        ['Live now', '$live', 'Bookings with status On air'],
        ['Completed bookings', '$done', 'Bookings with status Completed'],
        ['Assignments', '${asg.length}', 'Rows for this anchor in Assignments'],
        ['Assignments completed', '$asgDone', 'Assignments with status Completed'],
        ['Full crew assigned', '$crew of ${asg.length}', 'Cameraman, editor and driver all assigned'],
        ['Missing driver', '$needDrv', 'Open assignments where the driver is Unassigned'],
        ['Current status', '${a['status']}', 'Status on the anchor record'],
      ];

  List<List<String>> get bookingRows => [
        for (final b in bks) ['${b['program']}', '${b['studio']}', '${b['start']}', '${b['end']}', (tm('${b['end']}') - tm('${b['start']}')).toStringAsFixed(1), '${b['status']}']
      ];

  List<List<String>> get assignRows => [
        for (final x in asg) ['${x['program']}', '${x['time']}', '${x['studio']}', '${x['cameraman']}', '${x['editor']}', '${x['driver']}', '${x['status']}', full(x) ? 'Yes' : 'No']
      ];
}

String _q(Object? v) => '"${'$v'.replaceAll('"', '""')}"';
String _csv(List<List<Object?>> rows) => rows.map((r) => r.map(_q).join(',')).join('\n');
String _csec(String t, List<String> head, List<List<Object?>> rows) => '${_q(t)}\n${_csv(<List<Object?>>[head, ...rows])}\n';

String anchorCsv(List<Perf> ps) {
  final now = DateTime.now().toString().substring(0, 16);
  final b = StringBuffer()
    ..writeln(_csv([
      ['99TV Anchor Performance Report'],
      ['Generated', now],
      ['Scoring rule', 'Score % = shows today / daily target (4) x 100, capped at 100'],
      ['Grades', '75%+ Excellent; 50-74% On track; 1-49% Light load; 0% No shows'],
    ]))
    ..writeln()
    ..writeln(_csec('1. SUMMARY', ['Anchor', 'Role', 'Status', 'Shows today', 'Target', 'Score %', 'Grade', 'Bookings', 'Booked hours', 'Live now', 'Completed bookings', 'Assignments', 'Assignments completed', 'Full crew', 'Missing driver'], [
      for (final p in ps) [p.name, p.a['role'], p.a['status'], p.shows, p.target, p.pct, p.grade, p.bks.length, p.hours.toStringAsFixed(1), p.live, p.done, p.asg.length, p.asgDone, p.crew, p.needDrv]
    ]))
    ..writeln(_csec('2. SCORING BASIS (how each score was reached)', ['Anchor', 'Metric', 'Value', 'Calculation'], [
      for (final p in ps) for (final r in p.basis) [p.name, ...r]
    ]))
    ..writeln(_csec('3. STUDIO BOOKINGS', ['Anchor', 'Program', 'Studio', 'Start', 'End', 'Hours', 'Status'], [
      for (final p in ps) for (final r in p.bookingRows) [p.name, ...r]
    ]))
    ..writeln(_csec('4. ASSIGNMENTS AND CREW', ['Anchor', 'Program', 'Time', 'Studio', 'Cameraman', 'Editor', 'Driver', 'Status', 'Full crew'], [
      for (final p in ps) for (final r in p.assignRows) [p.name, ...r]
    ]));
  return b.toString();
}

void exportAnchors(BuildContext c, [List<Perf>? only]) {
  final ps = only ?? [for (final a in store.l('anchors')) Perf(a)];
  if (ps.isEmpty) return snack(c, 'No anchors to export.');
  Clipboard.setData(ClipboardData(text: anchorCsv(ps)));
  snack(c, 'CSV copied (${ps.length} anchor${ps.length == 1 ? '' : 's'}: summary, scoring basis, bookings, crew). Paste into Excel or Sheets.');
}

Widget crewPill(String l, String v) {
  final bad = v == 'Unassigned';
  return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: bad ? const Color(0xFFFFE3E6) : bgc, borderRadius: BorderRadius.circular(20)), child: Text('$l: $v', style: TextStyle(color: bad ? const Color(0xFFB4172B) : tx, fontSize: 10.5, fontWeight: FontWeight.w700)));
}

Widget secHead(String t, [String? s]) => Padding(padding: const EdgeInsets.only(top: 22, bottom: 8), child: title(t, s));

void perfSheet(BuildContext c, M anchor) {
  showModalBottomSheet(
      context: c,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      constraints: const BoxConstraints(maxWidth: 760),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      builder: (sheet) => AnimatedBuilder(
          animation: store,
          builder: (_, __) {
            final p = Perf(anchor);
            return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    avatar(p.name, s: 52),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(p.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -.6)), Text('${p.a['role']} · ${p.a['status']}', style: const TextStyle(color: mut, fontSize: 12.5))])),
                    IconButton(onPressed: () => Navigator.pop(sheet), icon: const Icon(Icons.close_rounded)),
                  ]),
                  const SizedBox(height: 14),
                  Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: const Color(0xFFFFF4F5), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFF6D5D9))),
                      child: Row(children: [
                        SizedBox(width: 78, height: 78, child: Stack(fit: StackFit.expand, children: [CircularProgressIndicator(value: p.pct / 100, strokeWidth: 8, color: red, backgroundColor: const Color(0xFFF3D9DD)), Center(child: Text('${p.pct}%', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)))])),
                        const SizedBox(width: 16),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [chip(p.grade), const SizedBox(height: 8), Text(p.verdict, style: const TextStyle(fontSize: 12.5, height: 1.4, color: tx))])),
                      ])),
                  secHead('How we reached ${p.pct}%', 'Every number below is read live from your data'),
                  for (final r in p.basis)
                    Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFEEF0F4)))),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(r[0], style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)), Text(r[2], style: const TextStyle(color: mut, fontSize: 10.5))])),
                          const SizedBox(width: 12),
                          Text(r[1], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                        ])),
                  secHead('Shows & bookings (${p.bks.length})', 'Evidence for airtime and completion'),
                  if (p.bks.isEmpty) const Text('No bookings for this anchor.', style: TextStyle(color: mut)),
                  for (final b in p.bks)
                    ListTile(contentPadding: EdgeInsets.zero, title: Text('${b['program']}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)), subtitle: Text('${b['studio']} · ${b['start']}–${b['end']} · ${(tm('${b['end']}') - tm('${b['start']}')).toStringAsFixed(1)} h'), trailing: chip('${b['status']}')),
                  secHead('Assignments & crew (${p.asg.length})', 'Evidence for crew readiness'),
                  if (p.asg.isEmpty) const Text('No assignments for this anchor.', style: TextStyle(color: mut)),
                  for (final x in p.asg)
                    Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: bgc, borderRadius: BorderRadius.circular(14)),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [Expanded(child: Text('${x['program']}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13))), chip('${x['status']}')]),
                          Text('${x['time']} · ${x['studio']}', style: const TextStyle(color: mut, fontSize: 11.5)),
                          const SizedBox(height: 8),
                          Wrap(spacing: 6, runSpacing: 6, children: [crewPill('Camera', '${x['cameraman']}'), crewPill('Editor', '${x['editor']}'), crewPill('Driver', '${x['driver']}'), chip(Perf.full(x) ? 'Full crew' : 'Crew incomplete')]),
                        ])),
                  const SizedBox(height: 20),
                  Wrap(spacing: 8, runSpacing: 8, children: [pbtn('Copy full CSV', () => exportAnchors(sheet, [p]), i: Icons.file_download_outlined), obtn('Close', () => Navigator.pop(sheet), i: Icons.close_rounded)]),
                ]));
          }));
}

// ───────────────────────── Accounts & role workspaces ─────────────────────────
class Acct {
  final String role, email, name, desc, coll, fld;
  final IconData icon;
  const Acct(this.role, this.email, this.name, this.desc, this.coll, this.fld, this.icon);
}

const demoPass = '123456';
const accts = [
  Acct('Manager', 'manager@99tv.demo', 'Ankit Reddy', 'Operations dashboard – full control', '', '', Icons.admin_panel_settings_rounded),
  Acct('Anchor', 'anchor@99tv.demo', 'Anjali Sharma', 'On-air talent – shows, crew & score', 'anchors', 'anchor', Icons.mic_rounded),
  Acct('Driver', 'driver@99tv.demo', 'Ravi Kumar', 'Crew transport – pickups & trips', 'drivers', 'driver', Icons.local_taxi_rounded),
  Acct('Production', 'production@99tv.demo', 'Manoj Kumar', 'Editor – edit queue & deadlines', 'eds', 'editor', Icons.content_cut_rounded),
  Acct('Cameraman', 'cameraman@99tv.demo', 'Sandeep Raju', 'Camera crew – calls & studio kit', 'cams', 'cameraman', Icons.videocam_rounded),
];
final session = ValueNotifier<Acct?>(null);
void logout() {
  session.value = null;
  nav.value = 0;
}

M? mine(Acct a) {
  for (final r in store.l(a.coll)) {
    if (r['name'] == a.name) return r;
  }
  return null;
}

M? studioOf(String n) {
  for (final s in store.l('studios')) {
    if (s['name'] == n) return s;
  }
  return null;
}

List<M> myAssigns(Acct a) => store.l('assigns').where((x) => x[a.fld] == a.name).toList()..sort((x, y) => '${x['time']}'.compareTo('${y['time']}'));
int bufMin() => (((store.d['set'] as Map?)?['buffer']) as num?)?.toInt() ?? 15;
String startOf(String t) => t.split(RegExp('[–-]')).first.trim();
String endOf(String t) => t.split(RegExp('[–-]')).last.trim();
String minus(String hhmm, int m) {
  try {
    final p = hhmm.split(':');
    final tot = (int.parse(p[0]) * 60 + int.parse(p[1]) - m).clamp(0, 1439).toInt();
    return '${(tot ~/ 60).toString().padLeft(2, '0')}:${(tot % 60).toString().padLeft(2, '0')}';
  } catch (_) {
    return hhmm;
  }
}

Widget emptyCard(String m) => Cardx(child: Center(child: Padding(padding: const EdgeInsets.all(14), child: Text(m, style: const TextStyle(color: mut)))));

String heroSub(Acct a, M r) => switch (a.role) {
      'Anchor' => '${r['role']} · 99TV',
      'Driver' => '${r['vehicle']} · ${r['location']}',
      'Production' => '${r['specialty']} · ${r['pkg']}',
      _ => '${r['specialty']} · Shift ${r['shift']}',
    };

Widget hero(Acct a, M r) {
  final h = DateTime.now().hour;
  final g = h < 12 ? 'Good morning' : h < 17 ? 'Good afternoon' : 'Good evening';
  return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF11151D), Color(0xFF2A1A22)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(22), boxShadow: const [BoxShadow(color: Color(0x2211151D), blurRadius: 24, offset: Offset(0, 10))]),
      child: Row(children: [
        avatar(a.name, s: 58),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(g, style: const TextStyle(color: Colors.white60, fontSize: 12)), Text(a.name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -.6)), Text(heroSub(a, r), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 11.5))])),
        const SizedBox(width: 8),
        chip('${r['status']}'),
      ]));
}

Widget statusPicker(BuildContext c, String coll, M r) => Cardx(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      title('My status', 'Tap to update — your manager sees this live'),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final s in cfgs[coll]!.st)
          ChoiceChip(
              label: Text(s),
              selected: r['status'] == s,
              showCheckmark: false,
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFFFFE3E6),
              side: BorderSide(color: r['status'] == s ? red : const Color(0xFFE1E5EC)),
              labelStyle: TextStyle(fontWeight: FontWeight.w700, color: r['status'] == s ? red : tx),
              onSelected: (_) {
                r['status'] = s;
                store.persist();
                snack(c, 'Status set to $s');
              }),
      ]),
    ]));

Widget crewCard(List<M> jobs, {String heading = 'My crew'}) => Cardx(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      title(heading, 'Everyone working on your assignments'),
      const SizedBox(height: 10),
      if (jobs.isEmpty) const Text('No assignments yet.', style: TextStyle(color: mut)),
      for (final x in jobs)
        Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: bgc, borderRadius: BorderRadius.circular(14)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Expanded(child: Text('${x['program']}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13))), chip('${x['status']}')]),
              Text('${x['time']} · ${x['studio']}', style: const TextStyle(color: mut, fontSize: 11.5)),
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 6, children: [crewPill('Camera', '${x['cameraman']}'), crewPill('Editor', '${x['editor']}'), crewPill('Driver', '${x['driver']}')]),
            ])),
    ]));

// ── Anchor ──
Widget anchorHome(BuildContext c, Acct a, M r) {
  final p = Perf(r);
  final pending = p.bks.where((b) => b['status'] != 'Completed').toList();
  final next = pending.isEmpty ? null : pending.first;
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    statusPicker(c, 'anchors', r),
    const SizedBox(height: 16),
    Grid([
      stat('Shows today', '${r['shows']}', 'Target ${p.target}', Icons.mic_rounded),
      stat('My score', '${p.pct}%', p.grade, Icons.trending_up_rounded),
      stat('Next show', next == null ? '—' : '${next['start']}', next == null ? 'Nothing pending' : '${next['program']}', Icons.schedule_rounded),
      stat('Booked airtime', '${p.hours.toStringAsFixed(1)} h', '${p.bks.length} bookings', Icons.live_tv_rounded),
    ], max: 4),
    const SizedBox(height: 16),
    Cardx(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      title('My shows today', 'Tap the arrow to move a show to its next stage'),
      const SizedBox(height: 6),
      if (p.bks.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('No shows booked yet.', style: TextStyle(color: mut))),
      for (final b in p.bks)
        ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('${b['program']}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
            subtitle: Text('${b['start']}–${b['end']} · ${b['studio']}'),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              chip('${b['status']}'),
              IconButton(
                  tooltip: 'Next stage',
                  icon: const Icon(Icons.skip_next_rounded),
                  onPressed: () {
                    store.cycle('bookings', b);
                    snack(c, '${b['program']}: ${b['status']}');
                  }),
            ])),
    ])),
    const SizedBox(height: 16),
    crewCard(p.asg),
    const SizedBox(height: 16),
    Cardx(
        onTap: () => perfSheet(c, r),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Expanded(child: title('My performance', p.grade)), Text('${p.pct}%', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: red))]),
          const SizedBox(height: 10),
          ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: p.pct / 100, minHeight: 9, color: red, backgroundColor: const Color(0xFFEDF0F4))),
          const SizedBox(height: 10),
          Text(p.verdict, style: const TextStyle(color: mut, fontSize: 12, height: 1.4)),
          const SizedBox(height: 8),
          const Align(alignment: Alignment.centerRight, child: Text('See how this is calculated ›', style: TextStyle(color: red, fontWeight: FontWeight.w800, fontSize: 12))),
        ])),
  ]);
}

// ── Driver ──
Widget driverHome(BuildContext c, Acct a, M r) {
  final jobs = myAssigns(a);
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    statusPicker(c, 'drivers', r),
    const SizedBox(height: 16),
    Grid([
      stat('Trips today', '${r['trips']}', 'Started so far', Icons.directions_car_rounded),
      stat('Vehicle', '${r['vehicle']}', 'Assigned to you', Icons.local_taxi_rounded),
      stat('Location', '${r['location']}', 'Last known', Icons.place_rounded),
      stat('Pickups', '${jobs.length}', 'Assigned today', Icons.assignment_rounded),
    ], max: 4),
    const SizedBox(height: 16),
    title('My pickups', 'Passenger, drop-off studio and time'),
    const SizedBox(height: 10),
    if (jobs.isEmpty) emptyCard('No pickups assigned. Enjoy the break.'),
    for (final j in jobs)
      Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Cardx(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Expanded(child: Text('${j['program']}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14))), chip('${j['status']}')]),
            const SizedBox(height: 4),
            Text('${j['time']} · Drop at ${j['studio']}', style: const TextStyle(color: mut, fontSize: 12)),
            const SizedBox(height: 10),
            Wrap(spacing: 6, runSpacing: 6, children: [crewPill('Pick up', '${j['anchor']}'), crewPill('Crew', '${j['cameraman']}')]),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              pbtn('Start trip', () {
                if (r['status'] == 'Off duty') return snack(c, 'You are off duty. Set your status to Available first.');
                r['status'] = 'On road';
                r['trips'] = ((r['trips'] as num?) ?? 0).toInt() + 1;
                store.persist();
                snack(c, 'Trip started for ${j['program']}.');
              }, i: Icons.navigation_rounded),
              obtn('Pickup done', () {
                r['status'] = 'Available';
                if (j['status'] == 'Scheduled' || j['status'] == 'Needs driver') j['status'] = 'Ready';
                store.persist();
                snack(c, 'Pickup done for ${j['program']}.');
              }, i: Icons.check_rounded),
            ]),
          ]))),
  ]);
}

// ── Production ──
Widget prodHome(BuildContext c, Acct a, M r) {
  final jobs = myAssigns(a);
  final open = jobs.where((j) => j['status'] != 'Completed').toList();
  final buf = bufMin();
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    statusPicker(c, 'eds', r),
    const SizedBox(height: 16),
    Grid([
      stat('Package', '${r['pkg']}', 'Currently assigned', Icons.inventory_2_rounded),
      stat('Edit jobs', '${jobs.length}', '${open.length} open', Icons.content_cut_rounded),
      stat('Next deadline', open.isEmpty ? '—' : minus(startOf('${open.first['time']}'), buf), open.isEmpty ? 'All clear' : '${open.first['program']}', Icons.alarm_rounded),
      stat('Stage', '${r['status']}', 'Your current stage', Icons.movie_filter_rounded),
    ], max: 4),
    const SizedBox(height: 16),
    title('My edit queue', 'Deliver $buf min before air time'),
    const SizedBox(height: 10),
    if (jobs.isEmpty) emptyCard('Nothing in your queue.'),
    for (final j in jobs)
      Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Cardx(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Expanded(child: Text('${j['program']}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14))), chip('${j['status']}')]),
            const SizedBox(height: 4),
            Text('On air ${j['time']} · ${j['studio']}', style: const TextStyle(color: mut, fontSize: 12)),
            const SizedBox(height: 4),
            Text('Deliver by ${minus(startOf('${j['time']}'), buf)}', style: const TextStyle(color: red, fontWeight: FontWeight.w800, fontSize: 12)),
            const SizedBox(height: 10),
            Wrap(spacing: 6, runSpacing: 6, children: [crewPill('Anchor', '${j['anchor']}'), crewPill('Camera', '${j['cameraman']}')]),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              obtn('Start editing', () {
                r['status'] = 'Editing';
                r['pkg'] = '${j['program']}';
                store.persist();
                snack(c, 'Editing ${j['program']}.');
              }, i: Icons.play_arrow_rounded),
              obtn('Send to review', () {
                r['status'] = 'Review';
                store.persist();
                snack(c, '${j['program']} sent to review.');
              }, i: Icons.rate_review_rounded),
              pbtn('Mark ready', () {
                if (j['status'] != 'On air' && j['status'] != 'Completed') j['status'] = 'Ready';
                r['status'] = 'Available';
                store.persist();
                snack(c, '${j['program']} is ready for air.');
              }, i: Icons.check_rounded),
            ]),
          ]))),
  ]);
}

// ── Cameraman ──
Widget camHome(BuildContext c, Acct a, M r) {
  final jobs = myAssigns(a);
  final open = jobs.where((j) => j['status'] != 'Completed').toList();
  final buf = bufMin();
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    statusPicker(c, 'cams', r),
    const SizedBox(height: 16),
    Grid([
      stat('Shift', '${r['shift']}', 'Today', Icons.schedule_rounded),
      stat('Specialty', '${r['specialty']}', 'Camera type', Icons.videocam_rounded),
      stat('Camera calls', '${jobs.length}', '${open.length} open', Icons.assignment_rounded),
      stat('Next call', open.isEmpty ? '—' : minus(startOf('${open.first['time']}'), buf), open.isEmpty ? 'No calls pending' : '${open.first['program']}', Icons.alarm_rounded),
    ], max: 4),
    const SizedBox(height: 16),
    title('My camera calls', 'Call time = air time minus $buf min setup buffer'),
    const SizedBox(height: 10),
    if (jobs.isEmpty) emptyCard('No camera calls assigned.'),
    for (final j in jobs)
      () {
        final s = studioOf('${j['studio']}');
        final maint = s != null && s['state'] == 'Maintenance';
        return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Cardx(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Expanded(child: Text('${j['program']}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14))), chip('${j['status']}')]),
              const SizedBox(height: 4),
              Text('${j['time']} · ${j['studio']}', style: const TextStyle(color: mut, fontSize: 12)),
              const SizedBox(height: 4),
              Text('Call time ${minus(startOf('${j['time']}'), buf)}', style: const TextStyle(color: red, fontWeight: FontWeight.w800, fontSize: 12)),
              if (s != null) ...[const SizedBox(height: 6), Text('Studio kit: ${s['equip']} · capacity ${s['cap']}', style: const TextStyle(color: mut, fontSize: 11.5))],
              if (maint) Container(margin: const EdgeInsets.only(top: 10), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFFFE3E6), borderRadius: BorderRadius.circular(10)), child: Row(children: [const Icon(Icons.warning_amber_rounded, size: 16, color: red), const SizedBox(width: 8), Expanded(child: Text('${j['studio']} is under maintenance. Check with your manager.', style: const TextStyle(color: Color(0xFFB4172B), fontWeight: FontWeight.w700, fontSize: 11.5)))])),
              const SizedBox(height: 10),
              Wrap(spacing: 6, runSpacing: 6, children: [crewPill('Anchor', '${j['anchor']}'), crewPill('Editor', '${j['editor']}')]),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                pbtn('Check in', () {
                  r['status'] = 'Assigned';
                  store.persist();
                  snack(c, 'Checked in at ${j['studio']}.');
                }, i: Icons.login_rounded),
                obtn('Wrap up', () {
                  r['status'] = 'Available';
                  store.persist();
                  snack(c, 'Wrapped up ${j['program']}.');
                }, i: Icons.check_rounded),
              ]),
            ])));
      }(),
  ]);
}

Widget staffHome(BuildContext c, Acct a, M r) {
  final Widget body = switch (a.role) {
    'Anchor' => anchorHome(c, a, r),
    'Driver' => driverHome(c, a, r),
    'Production' => prodHome(c, a, r),
    _ => camHome(c, a, r),
  };
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [hero(a, r), const SizedBox(height: 16), body]);
}

Widget staffSchedule(BuildContext c, Acct a) {
  final bk = [...store.l('bookings')]..sort((x, y) => '${x['start']}'.compareTo('${y['start']}'));
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    head('Schedule', 'Thursday, 19 November 2026 · IST', <Widget>[]),
    Cardx(pad: EdgeInsets.zero, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Padding(padding: const EdgeInsets.fromLTRB(18, 18, 18, 0), child: title('Studio timeline', 'Read-only view of today\'s bookings')), Timeline()])),
    const SizedBox(height: 16),
    Cardx(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      title('All broadcasts today'),
      const SizedBox(height: 6),
      for (final b in bk) ListTile(contentPadding: EdgeInsets.zero, leading: avatar('${b['anchor']}'), title: Text('${b['program']}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)), subtitle: Text('${b['start']}–${b['end']} · ${b['studio']} · ${b['anchor']}'), trailing: chip('${b['status']}')),
    ])),
  ]);
}

Widget staffProfile(BuildContext c, Acct a, M r) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      head('My profile', 'Your record as your manager sees it.', <Widget>[]),
      Cardx(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          avatar(a.name, s: 56),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(a.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)), Text('${a.role} · ${a.email}', style: const TextStyle(color: mut, fontSize: 12))])),
        ]),
        const SizedBox(height: 14),
        for (final f in cfgs[a.coll]!.f)
          if (r[f.k] != null)
            Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFEEF0F4)))),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 130, child: Text(f.l, style: const TextStyle(color: mut, fontSize: 12))), Expanded(child: Text('${r[f.k]}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)))])),
      ])),
      const SizedBox(height: 16),
      obtn('Sign out', logout, i: Icons.logout_rounded),
    ]);

class StaffShell extends StatefulWidget {
  final Acct a;
  const StaffShell(this.a, {super.key});
  @override
  State<StaffShell> createState() => _SS();
}

class _SS extends State<StaffShell> {
  int tab = 0;
  @override
  Widget build(BuildContext c) {
    final a = widget.a;
    return AnimatedBuilder(
        animation: store,
        builder: (_, __) {
          final r = mine(a);
          final Widget page = r == null
              ? Cardx(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [title('Profile not found', 'Your record was removed by the manager.'), const SizedBox(height: 12), pbtn('Sign out', logout, i: Icons.logout_rounded)]))
              : switch (tab) {
                  0 => staffHome(c, a, r),
                  1 => staffSchedule(c, a),
                  _ => staffProfile(c, a, r),
                };
          return Scaffold(
              appBar: AppBar(
                  backgroundColor: Colors.white,
                  surfaceTintColor: Colors.white,
                  titleSpacing: 16,
                  title: Row(children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), decoration: BoxDecoration(color: red, borderRadius: BorderRadius.circular(8)), child: const Text('99TV', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: -.5))),
                    const SizedBox(width: 10),
                    Text('${a.role} workspace', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  ]),
                  actions: [IconButton(tooltip: 'Sign out', onPressed: logout, icon: const Icon(Icons.logout_rounded)), const SizedBox(width: 4)]),
              body: SingleChildScrollView(key: ValueKey(tab), padding: const EdgeInsets.all(16), child: Align(alignment: Alignment.topCenter, child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 900), child: SizedBox(width: double.infinity, child: page)))),
              bottomNavigationBar: NavigationBar(
                  selectedIndex: tab,
                  indicatorColor: const Color(0xFFFFE3E6),
                  onDestinationSelected: (i) => setState(() => tab = i),
                  destinations: const [
                    NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded, color: red), label: 'My day'),
                    NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month_rounded, color: red), label: 'Schedule'),
                    NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded, color: red), label: 'Profile'),
                  ]));
        });
  }
}

// ───────────────────────── Shell / Login / App ─────────────────────────
const navItems = [
  ('Dashboard', Icons.dashboard_rounded),
  ('Studio Management', Icons.live_tv_rounded),
  ('Studio Schedule', Icons.calendar_month_rounded),
  ('Anchor Schedule', Icons.mic_rounded),
  ('Driver Schedule', Icons.local_taxi_rounded),
  ('Cameraman Schedule', Icons.videocam_rounded),
  ('Production Team', Icons.content_cut_rounded),
  ('Assignments', Icons.assignment_rounded),
  ('Reports', Icons.bar_chart_rounded),
  ('Settings', Icons.settings_rounded),
  ('Help & support', Icons.help_outline_rounded)
];

// NOTE: pages are intentionally NOT const, so they rebuild whenever the store changes.
Widget pageFor(int i) => switch (i) {
      0 => Dashboard(),
      1 => StudiosPage(),
      2 => SchedulePage(),
      3 => Roster('anchors'),
      4 => Roster('drivers'),
      5 => Roster('cams'),
      6 => Roster('eds'),
      7 => Roster('assigns'),
      8 => ReportsPage(),
      9 => SettingsPage(),
      _ => HelpPage(),
    };

class Side extends StatelessWidget {
  const Side({super.key});
  @override
  Widget build(BuildContext c) {
    final need = store.l('assigns').where((a) => a['driver'] == 'Unassigned' && a['status'] != 'Completed').length;
    return Container(
        width: 252,
        color: ink,
        padding: const EdgeInsets.fromLTRB(14, 24, 14, 16),
        child: SafeArea(
            child: Column(children: [
          Row(children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8), decoration: BoxDecoration(color: red, borderRadius: BorderRadius.circular(9), boxShadow: const [BoxShadow(color: Color(0x66E11D35), blurRadius: 18)]), child: const Text('99TV', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: -1))),
            const SizedBox(width: 12),
            const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('99TV', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)), Text('BROADCAST OPS', style: TextStyle(color: Color(0xFF778091), fontSize: 9, letterSpacing: 1.5, fontWeight: FontWeight.w700))])
          ]),
          const SizedBox(height: 26),
          Expanded(
              child: ListView(children: [
            for (var i = 0; i < navItems.length; i++)
              ValueListenableBuilder<int>(
                  valueListenable: nav,
                  builder: (_, cur, __) {
                    final on = cur == i;
                    return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  nav.value = i;
                                  if (Scaffold.maybeOf(c)?.isDrawerOpen ?? false) Navigator.pop(c);
                                },
                                child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
                                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: on ? const LinearGradient(colors: [Color(0x40E11D35), Color(0x10E11D35)]) : null, border: on ? Border.all(color: const Color(0x55E11D35)) : null),
                                    child: Row(children: [
                                      Icon(navItems[i].$2, size: 19, color: on ? const Color(0xFFFF6678) : const Color(0xFF818A9B)),
                                      const SizedBox(width: 12),
                                      Expanded(child: Text(navItems[i].$1, style: TextStyle(color: on ? Colors.white : const Color(0xFFA6ADBA), fontWeight: FontWeight.w600, fontSize: 12.5))),
                                      if (i == 7 && need > 0) Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1), decoration: BoxDecoration(color: red, borderRadius: BorderRadius.circular(20)), child: Text('$need', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)))
                                    ])))));
                  })
          ])),
          const Divider(color: Color(0xFF29303C)),
          Row(children: [avatar('Ankit Reddy', s: 36), const SizedBox(width: 10), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Ankit Reddy', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)), Text('Manager · Operations', style: TextStyle(color: Color(0xFF8992A2), fontSize: 10.5))])), IconButton(tooltip: 'Sign out', onPressed: logout, icon: const Icon(Icons.logout_rounded, color: Color(0xFF8992A2), size: 20))]),
        ])));
  }
}

class Shell extends StatelessWidget {
  const Shell({super.key});
  void bell(BuildContext c) {
    final a = store.alerts();
    showModalBottomSheet(
        context: c,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (sheet) => SafeArea(
            child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                  const SizedBox(height: 8),
                  if (a.isEmpty) const Padding(padding: EdgeInsets.all(16), child: Text('You\'re all caught up.', style: TextStyle(color: mut))),
                  for (final x in a)
                    ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.circle, size: 10, color: red),
                        title: Text(x.$1, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () {
                          nav.value = x.$2;
                          Navigator.pop(sheet);
                        }),
                ]))));
  }

  @override
  Widget build(BuildContext c) => AnimatedBuilder(
      animation: store,
      builder: (_, __) => ValueListenableBuilder<int>(
          valueListenable: nav,
          builder: (_, i, __) {
            final wide = MediaQuery.of(c).size.width >= 900, n = store.notifOn ? store.alerts().length : 0;
            final body = SingleChildScrollView(
                key: ValueKey(i),
                padding: EdgeInsets.all(wide ? 30 : 16),
                child: Align(alignment: Alignment.topCenter, child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1400), child: SizedBox(width: double.infinity, child: pageFor(i)))));
            final bellBtn = Stack(clipBehavior: Clip.none, children: [IconButton(onPressed: () => bell(c), icon: const Icon(Icons.notifications_none_rounded)), if (n > 0) Positioned(right: 4, top: 4, child: IgnorePointer(child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: red, shape: BoxShape.circle), child: Text('$n', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)))))]);
            if (wide) {
              return Scaffold(
                  body: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Side(),
                Expanded(
                    child: Column(children: [
                  Container(height: 68, padding: const EdgeInsets.symmetric(horizontal: 30), decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Color(0xFFE8EBF1)))), child: Row(children: [const Text('Operations  /  ', style: TextStyle(color: mut, fontSize: 12)), Text(navItems[i].$1, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)), const Spacer(), bellBtn, const SizedBox(width: 8), avatar('Ankit Reddy', s: 34)])),
                  Expanded(child: body),
                ]))
              ]));
            }
            return Scaffold(appBar: AppBar(backgroundColor: Colors.white, surfaceTintColor: Colors.white, title: Text(navItems[i].$1, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)), actions: [bellBtn]), drawer: Drawer(backgroundColor: ink, child: Side()), body: body);
          }));
}

class Login extends StatefulWidget {
  const Login({super.key});
  @override
  State<Login> createState() => _L();
}

class _L extends State<Login> {
  final k = GlobalKey<FormState>();
  final em = TextEditingController(), pw = TextEditingController();
  bool hide = true;
  String? err, picked;

  @override
  void dispose() {
    em.dispose();
    pw.dispose();
    super.dispose();
  }

  void fill(Acct a) => setState(() {
        em.text = a.email;
        pw.text = demoPass;
        err = null;
        picked = a.email;
      });

  void submit() {
    if (!k.currentState!.validate()) return;
    final e = em.text.trim().toLowerCase();
    final a = accts.where((x) => x.email == e).firstOrNull;
    if (a == null || pw.text != demoPass) {
      setState(() => err = 'Invalid email or password. Tap a demo account below to fill the form.');
      return;
    }
    nav.value = 0;
    session.value = a;
  }

  Widget demo() => Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: const Color(0xFFFFF4F5), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFF6D5D9))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Demo credentials', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
        const SizedBox(height: 2),
        const Text('Tap an account to fill the form • Password: $demoPass', style: TextStyle(color: mut, fontSize: 12)),
        const SizedBox(height: 8),
        for (final a in accts)
          InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => fill(a),
              child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: picked == a.email ? const Color(0xFFFFE3E6) : null),
                  child: Row(children: [
                    Container(width: 96, padding: const EdgeInsets.symmetric(vertical: 7), alignment: Alignment.center, decoration: BoxDecoration(color: const Color(0xFFFFE3E6), borderRadius: BorderRadius.circular(20)), child: Text(a.role, style: const TextStyle(color: Color(0xFFB4172B), fontWeight: FontWeight.w800, fontSize: 12))),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(a.email, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)), Text(a.desc, style: const TextStyle(color: mut, fontSize: 11))])),
                    const Icon(Icons.touch_app_rounded, color: red, size: 22),
                  ]))),
      ]));

  @override
  Widget build(BuildContext c) {
    final wide = MediaQuery.of(c).size.width > 800;
    final art = Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF10141D), Color(0xFF171E2B), Color(0xFF24131B)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
        padding: const EdgeInsets.all(48),
        alignment: Alignment.centerLeft,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('99', style: TextStyle(color: Colors.white, fontSize: 200, height: .9, fontWeight: FontWeight.w900, letterSpacing: -18)),
          const SizedBox(height: 22),
          const Text('BROADCAST OPERATIONS PLATFORM', style: TextStyle(color: Color(0xFFD9DCE4), letterSpacing: 3, fontSize: 11)),
        ]));
    final form = Center(
        child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Cardx(
                      pad: const EdgeInsets.all(28),
                      child: Form(
                          key: k,
                          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                            if (!wide) const Text('99TV', style: TextStyle(color: red, fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: -2)),
                            const Text('Welcome back', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -1)),
                            const Text('Sign in to your 99TV workspace.', style: TextStyle(color: mut)),
                            const SizedBox(height: 22),
                            TextFormField(controller: em, keyboardType: TextInputType.emailAddress, onChanged: (_) {
                              if (err != null) setState(() => err = null);
                            }, decoration: const InputDecoration(labelText: 'Email address', prefixIcon: Icon(Icons.mail_outline_rounded)), validator: (v) => (v ?? '').contains('@') ? null : 'Enter a valid email'),
                            const SizedBox(height: 14),
                            TextFormField(controller: pw, obscureText: hide, onChanged: (_) {
                              if (err != null) setState(() => err = null);
                            }, decoration: InputDecoration(labelText: 'Password', prefixIcon: const Icon(Icons.lock_outline_rounded), suffixIcon: IconButton(icon: Icon(hide ? Icons.visibility_off_outlined : Icons.visibility_outlined), onPressed: () => setState(() => hide = !hide))), validator: (v) => (v ?? '').length >= 4 ? null : 'Minimum 4 characters'),
                            if (err != null) Container(margin: const EdgeInsets.only(top: 12), width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFFFE3E6), borderRadius: BorderRadius.circular(12)), child: Text(err!, style: const TextStyle(color: Color(0xFFB4172B), fontWeight: FontWeight.w700, fontSize: 12.5))),
                            Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => snack(c, 'Password reset link sent to your email.'), child: const Text('Forgot password?', style: TextStyle(color: red, fontWeight: FontWeight.w700)))),
                            SizedBox(width: double.infinity, child: FilledButton(style: FilledButton.styleFrom(backgroundColor: ink, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: submit, child: const Text('Sign in', style: TextStyle(fontWeight: FontWeight.w800)))),
                          ]))),
                  const SizedBox(height: 16),
                  demo(),
                ]))));
    return Scaffold(backgroundColor: const Color(0xFFF7F8FB), body: wide ? Row(children: [Expanded(flex: 11, child: art), Expanded(flex: 9, child: form)]) : SafeArea(child: form));
  }
}

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext c) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: '99TV Broadcast Operations',
        theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: red, primary: red),
            scaffoldBackgroundColor: bgc,
            fontFamily: 'Roboto',
            inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE3E7EE))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE3E7EE))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: red, width: 1.5)))),
        home: ValueListenableBuilder<Acct?>(
            valueListenable: session,
            builder: (_, a, __) => a == null ? const Login() : a.role == 'Manager' ? const Shell() : StaffShell(a, key: ValueKey(a.email))),
      );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await store.init();
  runApp(const App());
}