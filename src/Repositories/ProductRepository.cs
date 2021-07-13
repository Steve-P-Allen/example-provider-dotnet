
using System.Collections.Generic;

namespace Products
{

  public interface IProductRepository
  {
      void AddProduct(Product product);
      void RemoveProducts();
      List<Product> GetProducts();
      Product GetProduct(int id);
  }

  public sealed class ProductRepository : IProductRepository
  {
      private readonly List<Product> _products = new List<Product>();

      public ProductRepository()
      {
        this._products.Add(new Product(1, "food", "pancake", "1.0.0"));
        this._products.Add(new Product(2, "food", "sanwhich", "1.0.0"));
      }

      public void AddProduct(Product product) {
        _products.Add(product);
      }

      public void RemoveProducts() {
        _products.Clear();
      }

      public List<Product> GetProducts() {
        return _products;
      }

      public Product GetProduct(int id) {
        return _products.Find(product => product.id == id);
      }
  }
}
