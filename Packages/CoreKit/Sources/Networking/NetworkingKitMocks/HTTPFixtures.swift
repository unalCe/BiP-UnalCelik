import Foundation

/// Captured from the live endpoints, trimmed but structurally identical.
public enum HTTPFixtures {
    /// `GET /cart/list`
    public static let productList = Data("""
    {
      "products" : [
         { "product_id" : "1", "name" : "Apples", "price" : 120,
           "image" : "https://s3-eu-west-1.amazonaws.com/developer-application-test/images/1.jpg" },
         { "product_id" : "6_id_is_a_string", "name" : "Pork", "price" : 343,
           "image" : "https://s3-eu-west-1.amazonaws.com/developer-application-test/images/6.jpg" },
         { "product_id" : "12", "name" : "Peppers", "price" : 9,
           "image" : "https://s3-eu-west-1.amazonaws.com/developer-application-test/images/12.jpg" }
      ]
    }
    """.utf8)

    /// `description` appears here but not in the list payload.
    public static let productDetail = Data("""
    {
       "product_id" : "1",
       "name" : "Apples",
       "price" : 120,
       "image" : "https://s3-eu-west-1.amazonaws.com/developer-application-test/images/1.jpg",
       "description" : "An apple a day keeps the doctor away."
    }
    """.utf8)

    /// Unknown ids return this, not a 404 — the bucket denies listing.
    public static let accessDenied = Data("""
    <?xml version="1.0" encoding="UTF-8"?>
    <Error><Code>AccessDenied</Code><Message>Access Denied</Message></Error>
    """.utf8)

    public static let emptyProductList = Data(#"{ "products" : [] }"#.utf8)

    public static let malformed = Data(#"{ "products" : "not-an-array" }"#.utf8)
}
