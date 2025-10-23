# PIMS - Product Inventory Management System

PIMS is a multi-tenant Rails application designed for managing product inventory in restaurants, retail, or food service businesses. It provides comprehensive tools for tracking suppliers, locations, products, batches, inventory levels, recipes, and orders.

## Features

- **Multi-Tenant Architecture**: Account-based isolation for multiple businesses
- **Inventory Management**: Track products, batches, suppliers, and locations
- **Batch Tracking**: Monitor expiration dates and supplier deliveries
- **Location-Based Inventory**: Manage stock across multiple warehouses/stores
- **Recipe Management**: Create and manage recipes with ingredients
- **Order Processing**: Handle orders and inventory adjustments
- **User Management**: Secure authentication with roles and permissions
- **Notifications**: Automated alerts for low stock and expirations
- **Integrations**: Stripe for payments, Square for POS
- **GraphQL API**: Modern API for frontend integration
- **Background Jobs**: Asynchronous processing with GoodJob
- **Internationalization**: Support for English, Spanish, and Vietnamese
- **Responsive UI**: Built with Tailwind CSS and Hotwire

## Requirements

- Ruby 3.2.0
- Rails 8.0.2
- PostgreSQL
- Node.js (for asset compilation)

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/mfifth/PIMS.git
   cd PIMS
   ```

2. Install dependencies:
   ```bash
   bundle install
   ```

3. Set up the database:
   ```bash
   rails db:create
   rails db:migrate
   rails db:seed
   ```

4. Set up credentials:
   ```bash
   rails credentials:edit
   ```
   Add necessary API keys (Stripe, Square, etc.)

5. Start the server:
   ```bash
   rails server
   ```

## Configuration

### Environment Variables

Set the following in your environment or `config/credentials.yml.enc`:

- `RAILS_MASTER_KEY`: Master key for encrypted credentials
- `DATABASE_URL`: PostgreSQL connection string
- `STRIPE_SECRET_KEY`: Stripe API key
- `SQUARE_ACCESS_TOKEN`: Square API token
- `GOOD_JOB_EXECUTION_MODE`: `:async` for background jobs

### Database

PIMS uses PostgreSQL with the following key tables:
- `accounts`: Multi-tenant accounts
- `users`: User accounts with roles
- `products`: Inventory items
- `batches`: Supplier deliveries
- `locations`: Warehouses/stores
- `inventory_items`: Stock levels
- `suppliers`: Vendor information
- `orders`: Order management
- `recipes`: Recipe definitions

## API

PIMS includes a GraphQL API for programmatic access. The schema is defined in `app/graphql/pims_schema.rb`.

Example query:
```graphql
query {
  products {
    id
    name
    sku
    inventoryItems {
      quantity
      location {
        name
      }
    }
  }
}
```

## Deployment

PIMS is configured for deployment on Fly.io with Neon PostgreSQL.

1. Set up Fly.io app:
   ```bash
   fly launch
   ```

2. Configure secrets:
   ```bash
   fly secrets set RAILS_MASTER_KEY=your_key
   fly secrets set DATABASE_URL=your_db_url
   ```

3. Deploy:
   ```bash
   fly deploy
   ```

## Testing

Run the test suite:
```bash
rails test
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests
5. Submit a pull request

## License

This project is licensed under the MIT License.
