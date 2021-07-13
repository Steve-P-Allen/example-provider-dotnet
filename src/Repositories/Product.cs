
namespace Products
{
    public class Product
    {
        public Product(int id, string type, string name, string version) {
            this.id = id;
            this.name = name;
            this.type = type;
            //this.nice = true;
            this.version = version;
        }
        public string type { get; set; }

        public string name { get; set; }

        public int id { get; set; }

        public string version { get; set; }

        //public bool nice {get; set;}
    }
}
