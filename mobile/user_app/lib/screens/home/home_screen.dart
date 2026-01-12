import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../models/product.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_constants.dart';
import '../../widgets/custom_text_field.dart';
import '../product/product_detail_screen.dart';
import '../product/product_list_screen.dart';
import '../cart/cart_screen.dart';
import '../profile/profile_screen.dart';
import '../orders/orders_screen.dart';

class HomeScreen extends StatefulWidget {
  static const String routeName = '/home';

  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  final List<Widget> _pages = [
    const HomePage(),
    const ProductListScreen(),
    const CartScreen(),
    const OrdersScreen(),
    const ProfileScreen(),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          return BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textSecondary,
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.search_outlined),
                activeIcon: Icon(Icons.search),
                label: 'Search',
              ),
              BottomNavigationBarItem(
                icon: Stack(
                  children: [
                    const Icon(Icons.shopping_cart_outlined),
                    if (cartProvider.itemCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 14,
                            minHeight: 14,
                          ),
                          child: Text(
                            '${cartProvider.itemCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                activeIcon: Stack(
                  children: [
                    const Icon(Icons.shopping_cart),
                    if (cartProvider.itemCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 14,
                            minHeight: 14,
                          ),
                          child: Text(
                            '${cartProvider.itemCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                label: 'Cart',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_outlined),
                activeIcon: Icon(Icons.receipt_long),
                label: 'Orders',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          );
        },
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      productProvider.loadInitialData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            final productProvider = Provider.of<ProductProvider>(context, listen: false);
            await productProvider.loadInitialData();
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(),
                
                const SizedBox(height: 20),
                
                // Search Bar
                _buildSearchBar(),
                
                const SizedBox(height: 20),
                
                // Categories
                _buildCategoriesSection(),
                
                const SizedBox(height: 24),
                
                // Featured Products
                _buildFeaturedSection(),
                
                const SizedBox(height: 24),
                
                // Recent Products
                _buildRecentProductsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, ${authProvider.user?.name ?? 'Guest'}!',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Text(
                  'What would you like to buy today?',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(24),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: authProvider.user?.avatar != null
                    ? CachedNetworkImage(
                        imageUrl: authProvider.user!.avatar!,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => const Icon(
                          Icons.person,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.person,
                        color: Colors.white,
                      ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return CustomTextField(
      controller: _searchController,
      label: '',
      hintText: 'Search products...',
      prefixIcon: Icons.search,
      onChanged: (value) {
        if (value.isNotEmpty) {
          final productProvider = Provider.of<ProductProvider>(context, listen: false);
          productProvider.searchProducts(value);
        }
      },
    );
  }

  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Categories',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to all categories
              },
              child: const Text(
                'See All',
                style: TextStyle(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Consumer<ProductProvider>(
          builder: (context, productProvider, child) {
            if (productProvider.categories.isEmpty) {
              return const SizedBox(
                height: 80,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            return SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: productProvider.categories.length,
                itemBuilder: (context, index) {
                  final category = productProvider.categories[index];
                  return _CategoryItem(category: category);
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFeaturedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Featured Products',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed(ProductListScreen.routeName);
              },
              child: const Text(
                'See All',
                style: TextStyle(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Consumer<ProductProvider>(
          builder: (context, productProvider, child) {
            if (productProvider.featuredProducts.isEmpty) {
              return const SizedBox(
                height: 200,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            return SizedBox(
              height: 280,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: productProvider.featuredProducts.length,
                itemBuilder: (context, index) {
                  final product = productProvider.featuredProducts[index];
                  return _ProductCard(product: product);
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentProductsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Products',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Consumer<ProductProvider>(
          builder: (context, productProvider, child) {
            if (productProvider.products.isEmpty) {
              return const SizedBox(
                height: 200,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              itemCount: productProvider.products.length > 4 
                  ? 4 
                  : productProvider.products.length,
              itemBuilder: (context, index) {
                final product = productProvider.products[index];
                return _ProductCard(product: product);
              },
            );
          },
        ),
      ],
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final ProductCategory category;

  const _CategoryItem({
    Key? key,
    required this.category,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: AppColors.border,
                width: 1,
              ),
            ),
            child: category.image != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: CachedNetworkImage(
                      imageUrl: category.image!,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => const Icon(
                        Icons.category,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.category,
                    color: AppColors.textSecondary,
                  ),
          ),
          const SizedBox(height: 4),
          Text(
            category.name,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;

  const _ProductCard({
    Key? key,
    required this.product,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).pushNamed(
              ProductDetailScreen.routeName,
              arguments: product,
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: AspectRatio(
                  aspectRatio: 1.2,
                  child: CachedNetworkImage(
                    imageUrl: product.mainImage,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppColors.background,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.background,
                      child: const Icon(
                        Icons.image,
                        color: AppColors.textSecondary,
                        size: 48,
                      ),
                    ),
                  ),
                ),
              ),
              
              // Product Info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 4),
                      
                      Text(
                        product.vendor.name,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const Spacer(),
                      
                      // Price and Rating
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (product.onSale) ...[
                                Text(
                                  '${AppConstants.currencySymbol}${product.price}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ],
                              Text(
                                '${AppConstants.currencySymbol}${product.finalPrice}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: product.onSale 
                                      ? AppColors.error 
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                size: 16,
                                color: AppColors.ratingActive,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${product.rating}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}