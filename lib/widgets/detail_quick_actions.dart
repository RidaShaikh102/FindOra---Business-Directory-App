import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class DetailQuickActions extends StatelessWidget {
  final String contact;
  final String whatsapp;
  final String website;
  final String liveLocation;
  final String category;
  final String ownerEmail;
  final String currentEmail;
  final bool isLoadingCall;
  final bool isLoadingWhatsApp;
  final bool isLoadingLocate;
  final bool isLoadingWebsite;
  final VoidCallback onCall;
  final VoidCallback onWhatsApp;
  final VoidCallback onLocate;
  final VoidCallback onWebsite;
  final VoidCallback onInstagram;
  final VoidCallback onFacebook;
  final VoidCallback onServices;
  final VoidCallback onShare;

  const DetailQuickActions({
    super.key,
    required this.contact,
    required this.whatsapp,
    required this.website,
    required this.liveLocation,
    required this.category,
    required this.ownerEmail,
    required this.currentEmail,
    required this.isLoadingCall,
    required this.isLoadingWhatsApp,
    required this.isLoadingLocate,
    required this.isLoadingWebsite,
    required this.onCall,
    required this.onWhatsApp,
    required this.onLocate,
    required this.onWebsite,
    required this.onInstagram,
    required this.onFacebook,
    required this.onServices,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Quick actions",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0A2D3F),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      DetailActionButton(
                        icon: isLoadingCall
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                Icons.phone,
                                color: Colors.white,
                                semanticLabel: 'Call business',
                              ),
                        label: "Call",
                        isLoading: isLoadingCall,
                        onTap: isLoadingCall ? null : onCall,
                      ),
                      DetailActionButton(
                        icon: isLoadingWhatsApp
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : FaIcon(
                                FontAwesomeIcons.whatsapp,
                                color: Colors.white,
                                semanticLabel: 'Send WhatsApp message',
                              ),
                        label: "WhatsApp",
                        isLoading: isLoadingWhatsApp,
                        onTap: isLoadingWhatsApp ? null : onWhatsApp,
                      ),
                      DetailActionButton(
                        icon: isLoadingLocate
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                Icons.location_pin,
                                color: Colors.white,
                                semanticLabel: 'Locate on map',
                              ),
                        label: "Locate",
                        isLoading: isLoadingLocate,
                        onTap: isLoadingLocate ? null : onLocate,
                      ),
                      DetailActionButton(
                        icon: isLoadingWebsite
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                Icons.language,
                                color: Colors.white,
                                semanticLabel: 'Visit website',
                              ),
                        label: "Website",
                        isLoading: isLoadingWebsite,
                        onTap: isLoadingWebsite ? null : onWebsite,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      DetailActionButton(
                        icon: Icon(
                          Icons.design_services_rounded,
                          color: Colors.white,
                        ),
                        label: category == 'Restaurant'
                            ? 'Menu'
                            : category == 'Pharmacy'
                            ? 'Pills'
                            : 'Services',
                        onTap: onServices,
                      ),
                      DetailActionButton(
                        icon: Icon(Icons.share, color: Colors.white),
                        label: "Share",
                        onTap: onShare,
                      ),
                      DetailActionButton(
                        icon: const FaIcon(
                          FontAwesomeIcons.instagram,
                          color: Colors.white,
                          semanticLabel: 'Instagram',
                        ),
                        label: "Instagram",
                        onTap: onInstagram,
                      ),
                      DetailActionButton(
                        icon: const FaIcon(
                          FontAwesomeIcons.facebook,
                          color: Colors.white,
                          semanticLabel: 'Facebook',
                        ),
                        label: "Facebook",
                        onTap: onFacebook,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class DetailActionButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;

  const DetailActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 48,
          height: 48,
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            elevation: 3,
            shadowColor: Colors.black26,
            child: InkWell(
              onTap: isLoading ? null : onTap,
              customBorder: const CircleBorder(),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0A2D3F), Color(0xFF0A2D3F), Colors.teal],
                  ),
                  border: Border.all(
                    color: Colors.teal.withAlpha(89),
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: icon,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
