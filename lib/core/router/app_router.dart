import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../screens/auth/splash_screen.dart';
import '../../screens/auth/language_selection_screen.dart';
import '../../screens/auth/onboarding_screen.dart';
import '../../screens/auth/signup_screen.dart';
import '../../screens/auth/otp_verification_screen.dart';
import '../../screens/auth/profile_setup_screen.dart';
import '../../screens/auth/forgot_password_screen.dart';
import '../../screens/home/main_shell.dart';
import '../../screens/browse/categories_screen.dart';
import '../../screens/browse/product_list_screen.dart';
import '../../screens/browse/search_screen.dart';
import '../../screens/product/product_detail_screen.dart';
import '../../screens/product/all_reviews_screen.dart';
import '../../screens/vendor/vendor_profile_screen.dart';
import '../../screens/orders/place_order_screen.dart';
import '../../screens/orders/order_confirmation_screen.dart';
import '../../screens/orders/order_tracking_screen.dart';
import '../../screens/custom_request/custom_request_step1_screen.dart';
import '../../screens/custom_request/custom_request_step2_screen.dart';
import '../../screens/custom_request/custom_request_step3_screen.dart';
import '../../screens/custom_request/custom_request_step4_screen.dart';
import '../../screens/custom_request/request_submitted_screen.dart';
import '../../screens/custom_request/custom_request_status_screen.dart';
import '../../screens/custom_request/quote_accept_confirm_screen.dart';
import '../../screens/custom_request/quotes_list_screen.dart';
import '../../screens/chat/enquiry_screen.dart';
import '../../screens/chat/notifications_screen.dart';
import '../../screens/profile/saved_items_screen.dart';
import '../../screens/profile/edit_profile_screen.dart';
import '../../screens/orders/my_orders_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    // Auth Flow
    GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/language', builder: (_, __) => const LanguageSelectionScreen()),
    GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
    GoRoute(path: '/signup', builder: (_, __) => const SignUpScreen()),
    GoRoute(
      path: '/otp',
      builder: (_, state) => OTPVerificationScreen(phone: state.extra as String? ?? '+92 300 1234567'),
    ),
    GoRoute(path: '/profile-setup', builder: (_, __) => const ProfileSetupScreen()),
    GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),

    // Main Shell (bottom nav)
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(path: '/home', builder: (_, __) => const SizedBox()),
        GoRoute(path: '/browse', builder: (_, __) => const SizedBox()),
        GoRoute(path: '/request-tab', builder: (_, __) => const SizedBox()),
        GoRoute(path: '/orders-tab', builder: (_, __) => const SizedBox()),
        GoRoute(path: '/profile-tab', builder: (_, __) => const SizedBox()),
      ],
    ),

    // Browse
    GoRoute(path: '/categories', builder: (_, __) => const CategoriesScreen()),
    GoRoute(
      path: '/products',
      builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return ProductListScreen(
          categoryName: extra?['categoryName'] ?? 'All Products',
          subCategory: extra?['subCategory'],
        );
      },
    ),
    GoRoute(path: '/search', builder: (_, __) => const SearchScreen()),

    // Product & Vendor
    GoRoute(
      path: '/product/:id',
      builder: (_, state) => ProductDetailScreen(productId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/product/:id/reviews',
      builder: (_, state) => AllReviewsScreen(vendorId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/vendor/:id',
      builder: (_, state) => VendorProfileScreen(vendorId: state.pathParameters['id']!),
    ),

    // Orders
    GoRoute(
      path: '/place-order/:productId',
      builder: (_, state) => PlaceOrderScreen(productId: state.pathParameters['productId']!),
    ),
    GoRoute(
      path: '/order-confirmation/:orderId',
      builder: (_, state) => OrderConfirmationScreen(orderId: state.pathParameters['orderId']!),
    ),
    GoRoute(
      path: '/orders/:orderId',
      builder: (_, state) => OrderTrackingScreen(orderId: state.pathParameters['orderId']!),
    ),

    // Custom Request Flow
    GoRoute(path: '/custom-request/step1', builder: (_, __) => const CustomRequestStep1Screen()),
    GoRoute(path: '/custom-request/step2', builder: (_, __) => const CustomRequestStep2Screen()),
    GoRoute(path: '/custom-request/step3', builder: (_, __) => const CustomRequestStep3Screen()),
    GoRoute(path: '/custom-request/step4', builder: (_, __) => const CustomRequestStep4Screen()),
    GoRoute(path: '/custom-request/submitted', builder: (_, __) => const RequestSubmittedScreen()),
    GoRoute(
      path: '/custom-requests/:id',
      builder: (_, state) => CustomRequestStatusScreen(requestId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/custom-requests/:id/confirm',
      builder: (_, state) => QuoteAcceptConfirmScreen(
        requestId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(path: '/quotes', builder: (_, __) => const QuotesListScreen()),

    // Chat
    GoRoute(
      path: '/chat/:vendorId',
      builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return EnquiryScreen(
          vendorId: state.pathParameters['vendorId']!,
          productId: extra?['productId'],
        );
      },
    ),
    GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),

    // Profile
    GoRoute(path: '/saved-items', builder: (_, __) => const SavedItemsScreen()),
    GoRoute(path: '/edit-profile', builder: (_, __) => const EditProfileScreen()),
    GoRoute(path: '/my-orders', builder: (_, __) => const MyOrdersScreen()),
  ],
);
