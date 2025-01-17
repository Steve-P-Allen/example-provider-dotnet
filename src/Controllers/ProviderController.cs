﻿using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;

namespace Products.Controllers
{
    public class ProductsController : Controller
    {
        private IConfiguration _Configuration { get; }
        private readonly IProductRepository _Repository;

        // This would usually be from a Repository/Data Store

        public ProductsController(IConfiguration configuration, IProductRepository repository)
        {
            this._Configuration = configuration;
            this._Repository = repository;
        }

        [HttpGet]
        [Route("/products")]
        public IActionResult GetAll()
        {
            return new JsonResult(_Repository.GetProducts());
        }

        [HttpGet]
        [Route("/product/{id?}")]
        public IActionResult GetSingle(int id)
        {
            var product = _Repository.GetProduct(id);
            if (product != null) {
                return new JsonResult(product);
            }
            return new NotFoundResult();
        }
    }
}
