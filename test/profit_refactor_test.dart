
import 'package:flutter_test/flutter_test.dart';
import 'package:sellweb/features/catalogue/domain/entities/product_catalogue.dart';
import 'package:sellweb/features/sales/domain/entities/ticket_model.dart';
import 'package:sellweb/features/analytics/data/models/sales_analytics_model.dart';

void main() {
  group('Profit Calculation Refactor Verification', () {
    test('ProductCatalogue profit based on revenuePercentage', () {
      final product = ProductCatalogue(
        id: '1',
        creation: DateTime.now(),
        upgrade: DateTime.now(),
        documentCreation: DateTime.now(),
        documentUpgrade: DateTime.now(),
        salePrice: 150.0, // Should be irrelevant for PROFIT VALUE calculation if we use percentage strictly? 
                          // Wait, my logic is: profit = purchase * percentage.
        purchasePrice: 100.0,
        revenuePercentage: 30, // 30% markup
        quantity: 1.0,
      );

      // Profit Value = 100 * 0.30 = 30.
      expect(product.getBenefitsValue, 30.0);
      expect(product.totalProfit, 30.0);
      expect(product.getBenefits, '30%');
      expect(product.hasProfitMargin, true);
 
      // Test quantity multiplier
      final productQty2 = product.copyWith(quantity: 2.0);
      expect(productQty2.totalProfit, 60.0);
    });

    test('TicketModel profit aggregation', () {
       final product1 = ProductCatalogue(
        id: '1',
        nameMark: 'P1',
        description: 'P1',
        creation: DateTime.now(),
        upgrade: DateTime.now(),
        documentCreation: DateTime.now(),
        documentUpgrade: DateTime.now(),
        salePrice: 130.0, 
        purchasePrice: 100.0,
        revenuePercentage: 30, // Profit = 30
        quantity: 1.0,
      );

      final product2 = ProductCatalogue(
        id: '2',
        nameMark: 'P2',
        description: 'P2',
        creation: DateTime.now(),
        upgrade: DateTime.now(),
        documentCreation: DateTime.now(),
        documentUpgrade: DateTime.now(),
        salePrice: 300.0, 
        purchasePrice: 200.0,
        revenuePercentage: 50, // Profit = 100 (200 * 0.50)
        quantity: 1.0,
      );

      final ticket = TicketModel.fromProductCatalogues(
        products: [product1, product2],
      );

      // Total Cost = 100 + 200 = 300
      // Total Profit = 30 + 100 = 130
      
      expect(ticket.getProfit, 130.0);

      // Percentage Profit = (130 / 300) * 100 = 43.333... -> 43%
      expect(ticket.getPercentageProfit, 43); 

      // Test with discount
      final ticketWithDiscount = ticket.copyWith(discount: 10.0, discountIsPercentage: false);
      // Total Profit = 130 - 10 = 120
      expect(ticketWithDiscount.getProfit, 120.0);
      
      // Percentage Profit with discount
      // Total Cost = 300
      // Profit = 120
      // % = (120/300)*100 = 40%
      expect(ticketWithDiscount.getPercentageProfit, 40);
    });

    test('SalesAnalyticsModel profit metrics', () {
      final product1 = ProductCatalogue(
        id: '1',
        creation: DateTime.now(),
        upgrade: DateTime.now(),
        documentCreation: DateTime.now(),
        documentUpgrade: DateTime.now(),
        salePrice: 130.0, 
        purchasePrice: 100.0,
        revenuePercentage: 30, // Profit = 30
        quantity: 1.0,
      );

       // Ticket with 1 sold
       final ticket = TicketModel.fromProductCatalogues(
        products: [product1],
      );

      final analytics = SalesAnalyticsModel.fromTickets([ticket]);

      expect(analytics.totalProfit, 30.0);
      
      // Check profitable stats
      final productStat = analytics.mostProfitableProducts.first;
      expect(productStat['totalProfit'], 30.0);
      expect(productStat['profitPerUnit'], 30.0);
    });
  });
}
