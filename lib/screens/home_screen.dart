import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../db/database_helper.dart';
import '../models/purchase.dart';
import 'add_purchase_screen.dart';
import 'usage_log_screen.dart';
import 'insights_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Purchase> _purchases = [];
  Map<int, int> _usageCounts = {};
  BannerAd? _bannerAd;
  bool _bannerAdReady = false;
  InterstitialAd? _interstitialAd;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadBannerAd();
    _loadInterstitialAd();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111',
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _bannerAdReady = true),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _bannerAd = null;
        },
      ),
    )..load();
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/1033173712',
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (_) => _interstitialAd = null,
      ),
    );
  }

  void _showInterstitialAd() {
    if (_interstitialAd != null) {
      _interstitialAd!.show();
      _interstitialAd = null;
      _loadInterstitialAd();
    }
  }

  Future<void> _loadData() async {
    final purchases = await DatabaseHelper.instance.getPurchases();
    final counts = <int, int>{};
    for (final p in purchases) {
      if (p.id != null) {
        counts[p.id!] = await DatabaseHelper.instance.getUsageCount(p.id!);
      }
    }
    setState(() {
      _purchases = purchases;
      _usageCounts = counts;
    });
  }

  double _costPerUse(Purchase p) {
    final count = _usageCounts[p.id] ?? 0;
    if (count == 0) return p.cost;
    return p.cost / count;
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('CostPerUse'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.insights),
            onPressed: () async {
              _showInterstitialAd();
              await Navigator.push(context, MaterialPageRoute(builder: (_) => InsightsScreen(purchases: _purchases, usageCounts: _usageCounts)));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _purchases.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_bag_outlined, size: 64, color: cs.primary),
                        const SizedBox(height: 16),
                        Text('No purchases yet', style: TextStyle(fontSize: 18, color: cs.onSurfaceVariant)),
                        const SizedBox(height: 8),
                        Text('Tap + to add your first purchase', style: TextStyle(color: cs.onSurfaceVariant)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _purchases.length,
                    itemBuilder: (ctx, i) {
                      final p = _purchases[i];
                      final count = _usageCounts[p.id] ?? 0;
                      final cpu = _costPerUse(p);
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: cs.primaryContainer,
                            child: Text(p.name[0].toUpperCase(), style: TextStyle(color: cs.onPrimaryContainer, fontWeight: FontWeight.bold)),
                          ),
                          title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${p.category} • $count uses'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('$${cpu.toStringAsFixed(2)}/use', style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold)),
                              Text('$${p.cost.toStringAsFixed(2)} total', style: const TextStyle(fontSize: 11)),
                            ],
                          ),
                          onTap: () async {
                            await Navigator.push(context, MaterialPageRoute(builder: (_) => UsageLogScreen(purchase: p)));
                            _loadData();
                          },
                          onLongPress: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Delete Purchase'),
                                content: Text('Delete "${p.name}" and all its usage logs?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                  TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                                ],
                              ),
                            );
                            if (confirm == true && p.id != null) {
                              await DatabaseHelper.instance.deletePurchase(p.id!);
                              _loadData();
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
          if (_bannerAdReady && _bannerAd != null)
            SizedBox(
              height: _bannerAd!.size.height.toDouble(),
              width: _bannerAd!.size.width.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPurchaseScreen()));
          _loadData();
        },
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        child: const Icon(Icons.add),
      ),
    );
  }
}
