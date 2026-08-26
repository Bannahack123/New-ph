import 'package:flutter/material.dart';
import '../web_modules_registry.dart';

class WebModuleGrid extends StatelessWidget {
  final String currentView;
  final Function(String hubId, String hubTitle) onHubTap;
  final Function(String title, IconData icon, String navKey) onActionTap;
  final VoidCallback onBackToHome;

  const WebModuleGrid({
    super.key,
    required this.currentView,
    required this.onHubTap,
    required this.onActionTap,
    required this.onBackToHome,
  });

  @override
  Widget build(BuildContext context) {
    if (currentView == "HOME") {
      return _buildLevel0HubsGrid(context);
    } else {
      return _buildLevel1SubActionsGrid(context);
    }
  }

  // =========================================================================
  // LEVEL 0: PREMIUM OBSIDIAN 8 HUBS GRID
  // =========================================================================
  Widget _buildLevel0HubsGrid(BuildContext context) {
    final hubs = WebModulesRegistry.allHubs;

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 1150 ? 4 : (constraints.maxWidth > 750 ? 2 : 1);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: hubs.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.35, // Perfectly balanced card proportion
          ),
          itemBuilder: (context, index) {
            final hub = hubs[index];
            final Color color = hub.color;

            return InkWell(
              onTap: () => onHubTap(hub.id, hub.title),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF19243B), Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: color.withOpacity(0.35), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top Row: Icon + Title + Arrow
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: color.withOpacity(0.4)),
                          ),
                          child: Icon(hub.icon, color: color, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            hub.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(Icons.arrow_forward_rounded, color: color.withOpacity(0.8), size: 16),
                      ],
                    ),

                    // Middle: Subtitle
                    Text(
                      hub.subtitle,
                      style: const TextStyle(color: Colors.white60, fontSize: 10.5, height: 1.3),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Bottom: Feature Chips (No empty dead space!)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: hub.subActions.take(3).map((act) {
                          return Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black38,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(act.icon, size: 11, color: color),
                                const SizedBox(width: 4),
                                Text(
                                  act.title,
                                  style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // =========================================================================
  // LEVEL 1: DRILLDOWN WITH CLEAN HEADER & SLEEK CARDS
  // =========================================================================
  Widget _buildLevel1SubActionsGrid(BuildContext context) {
    final currentHub = WebModulesRegistry.allHubs.firstWhere(
      (h) => h.id == currentView,
      orElse: () => WebModulesRegistry.allHubs.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Back Header Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                onPressed: onBackToHome,
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: const Text("BACK TO MAIN HUBS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              ),
              const SizedBox(width: 18),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: currentHub.color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(currentHub.icon, color: currentHub.color, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentHub.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    currentHub.subtitle,
                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Sub-Actions Cards Grid
        LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount = constraints.maxWidth > 950 ? 3 : (constraints.maxWidth > 600 ? 2 : 1);

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: currentHub.subActions.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.85,
              ),
              itemBuilder: (context, index) {
                final act = currentHub.subActions[index];
                final Color color = act.color;

                return InkWell(
                  onTap: () => onActionTap(act.title, act.icon, act.key),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF19243B), Color(0xFF0F172A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: color.withOpacity(0.4), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black38,
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: color.withOpacity(0.35)),
                          ),
                          child: Icon(act.icon, color: color, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                act.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                act.subtitle,
                                style: const TextStyle(color: Colors.white54, fontSize: 9.5),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
