Library Books REST API



Overview



This REST API manages books in a library. It supports listing, retrieving, creating, updating, deleting, and searching for books by author.



Base URL: "/api/books"



Book Resource



Each book has the following fields:



\- "id": Unique identifier for the book.

\- "title": Title of the book.

\- "author": Name of the author.

\- "publishedYear": Year the book was published.

\- "available": Whether the book is available to borrow.



Endpoints



1\. List All Books



\- Method: "GET"

\- Path: "/api/books"

\- Description: Returns a list of all books in the library.

\- Success status: "200 OK"

\- Request body: None.



2\. Get One Book



\- Method: "GET"

\- Path: "/api/books/:id"

\- Description: Returns details for a specific book using its ID.

\- Success status: "200 OK"

\- Request body: None.

\- Possible error: "404 Not Found" if the book does not exist.



Example: "GET /api/books/12"



3\. Create a Book



\- Method: "POST"

\- Path: "/api/books"

\- Description: Creates a new book in the library.

\- Success status: "201 Created"



Example request body:



{

&#x20; "title": "Things Fall Apart",

&#x20; "author": "Chinua Achebe",

&#x20; "publishedYear": 1958,

&#x20; "available": true

}



4\. Update a Book



\- Method: "PUT"

\- Path: "/api/books/:id"

\- Description: Updates the details of an existing book.

\- Success status: "200 OK"



Example request body:



{

&#x20; "title": "Things Fall Apart",

&#x20; "author": "Chinua Achebe",

&#x20; "publishedYear": 1958,

&#x20; "available": false

}



5\. Delete a Book



\- Method: "DELETE"

\- Path: "/api/books/:id"

\- Description: Deletes a book from the library.

\- Success status: "204 No Content"

\- Request body: None.



Example: "DELETE /api/books/12"



6\. List Books by Author



\- Method: "GET"

\- Path: "/api/books?author=Chinua%20Achebe"

\- Description: Returns books written by the specified author. The "author" query parameter filters the results.

\- Success status: "200 OK"

\- Request body: None.



Example: "GET /api/books?author=Chinua%20Achebe"



Error Responses



400 Bad Request



Returned when the request contains invalid data or fails validation.



Example: Creating a book without a title or with an invalid "publishedYear".



404 Not Found



Returned when the requested book does not exist.



Example: Requesting "GET /api/books/9999" when book "9999" is not in the library.



Summary



The API uses standard HTTP methods and status codes:



\- "GET" retrieves books.

\- "POST" creates a book.

\- "PUT" updates a book.

\- "DELETE" removes a book.

\- "200 OK" indicates a successful retrieval or update.

\- "201 Created" indicates successful creation.

\- "204 No Content" indicates successful deletion.

\- "400 Bad Request" and "404 Not Found" describe common errors.
