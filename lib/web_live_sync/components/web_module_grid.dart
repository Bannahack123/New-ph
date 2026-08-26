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
  // LEVEL 0: COMPACT & SLEEK 8 HUBS GRID
  // =========================================================================
  Widget _buildLevel0HubsGrid(BuildContext context) {
    final hubs = WebModulesRegistry.allHubs;

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 1100 ? 4 : (constraints.maxWidth > 700 ? 2 : 1);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: hubs.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.65, // Sleek rectangular height
          ),
          itemBuilder: (context, index) {
            final hub = hubs[index];
            final Color color = hub.color;

            return InkWell(
              onTap: () => onHubTap(hub.id, hub.title),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: color.withOpacity(0.3)),
                      ),
                      child: Icon(hub.icon, color: color, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            hub.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            hub.subtitle,
                            style: const TextStyle(color: Colors.white54, fontSize: 9.5),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 12),
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
  // LEVEL 1: SUB-ACTIONS GRID WITH STEP BACK HEADER
  // =========================================================================
  Widget _buildLevel1SubActionsGrid(BuildContext context) {
    final currentHub = WebModulesRegistry.allHubs.firstWhere(
      (h) => h.id == currentView,
      orElse: () => WebModulesRegistry.allHubs.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dedicated Back Action Header Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white12,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                onPressed: onBackToHome,
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: const Text("BACK TO MODULES", style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: currentHub.color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(currentHub.icon, color: currentHub.color, size: 18),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentHub.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
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
        const SizedBox(height: 18),

        // Compact Sub-Actions Grid
        LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount = constraints.maxWidth > 950 ? 3 : (constraints.maxWidth > 600 ? 2 : 1);

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: currentHub.subActions.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.8, // Sleek compact cards
              ),
              itemBuilder: (context, index) {
                final act = currentHub.subActions[index];
                final Color color = act.color;

                return InkWell(
                  onTap: () => onActionTap(act.title, act.icon, act.key),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: color.withOpacity(0.35), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(act.icon, color: color, size: 20),
                        ),
                        const SizedBox(width: 12),
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
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                act.subtitle,
                                style: const TextStyle(color: Colors.white54, fontSize: 9.5),
                                maxLines: 1,
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
