TicketHub — Event Ticketing System Design



1\. Requirements



TicketHub is a website where users discover concerts and events, select seats, purchase tickets, and view their bookings.



Functional requirements



1\. Users can register, sign in, and manage their accounts.

2\. Users can browse, search, and filter events by date, location, and category.

3\. Users can view event details, prices, and real-time seat availability.

4\. Users can temporarily hold available seats while completing checkout.

5\. Users can pay for held seats and receive booking confirmation.

6\. Users can view their purchased tickets and order history.

7\. Event organizers can create events, configure seats, and set ticket prices.

8\. The system releases expired or unpaid seat holds automatically.



Non-functional requirements



\- Speed: Event listings should load within 300 ms at the 95th percentile under normal conditions. Seat availability and checkout should respond quickly, with clear loading states during peak demand.

\- Correctness: A seat must never be sold to two different customers. Payments and orders must remain consistent even when requests are retried or services fail.

\- Fairness: Popular sales should use a controlled waiting room or queue. Customers should receive a fair opportunity to purchase without gaining an advantage through excessive requests or automated bots.

\- Availability: Browsing should remain available during high traffic. Checkout may be temporarily queued or throttled rather than allowing incorrect sales.

\- Scalability: Application servers should scale horizontally to handle sudden increases in traffic.

\- Security: Use HTTPS, authentication, authorization, payment-provider integration, input validation, and rate limiting.

\- Reliability: Use database backups, monitoring, health checks, and recovery procedures.

\- Usability: Show clear seat statuses, prices, hold-expiration times, payment results, and errors.



These response-time targets are design goals, not measured results.



2\. Traffic and Capacity Estimates



A. Normal-day traffic



Given:



\- Registered users: 2,000,000.

\- Daily visitors: 50,000.

\- Pages viewed per visitor: 10.

\- Tickets sold per day: 5,000.



Page views per day



50,000 visitors × 10 pages = 500,000 page views/day.



Average page requests per second



500,000 ÷ 86,400 ≈ 5.8 requests/second.



Assuming peak normal traffic is five times the average:



5.8 × 5 ≈ 29 requests/second.



Ticket sales rate



5,000 tickets ÷ 86,400 ≈ 0.058 tickets/second.



This is approximately 208 tickets per hour on average. Actual sales will vary by event and time.



B. Big-sale traffic



A popular concert has 20,000 seats, and 200,000 people try to buy tickets within 10 minutes.



Incoming purchase attempts per second



200,000 ÷ (10 × 60) ≈ 333 attempts/second.



Seat demand compared with supply



200,000 potential buyers ÷ 20,000 seats = 10 buyers per seat on average.



Only 10% of those potential buyers can receive a seat if all seats are sold individually. The other 180,000 people cannot all receive tickets for this concert.



Potential attempt volume



333 attempts/second × 600 seconds ≈ 200,000 attempts.



This represents purchase attempts, not successful sales. Browsing, refreshing, seat selection, and payment calls can generate additional requests.



C. Comparison



Metric| Normal day| Big-sale window

Visitors / potential buyers| 50,000 per day| 200,000 in 10 minutes

Page views / purchase attempts| 500,000 page views/day| 200,000 purchase attempts

Average request rate for the stated activity| 5.8 page requests/sec| 333 purchase attempts/sec

Ticket supply or sales| 5,000 tickets/day| 20,000 seats

Main challenge| Efficient everyday browsing| Overload, fairness, and seat correctness



The big-sale purchase-attempt rate is about 58 times the average normal-day page-request rate. This is not a perfect like-for-like comparison because one measures page views and the other measures purchase attempts, but it illustrates the sudden increase in pressure on the checkout system.



Capacity strategy



\- Serve static content and event images through a CDN.

\- Cache event details and other read-heavy data.

\- Scale application servers horizontally.

\- Put users into a waiting room during high-demand sales.

\- Rate-limit requests and protect checkout services.

\- Give the database final authority over seat availability.

\- Use load tests to determine the actual server and database capacity required.



3\. API Design



The API uses REST conventions and JSON request and response bodies. All endpoints use HTTPS. Authenticated endpoints require a valid session or access token.



Method| Endpoint| Purpose| Success status

GET| "/api/events"| Browse and search events| 200 OK

GET| "/api/events/{eventId}"| View event details| 200 OK

GET| "/api/events/{eventId}/seats"| View seat availability and prices| 200 OK

POST| "/api/events/{eventId}/holds"| Temporarily hold selected seats| 201 Created

POST| "/api/orders"| Create an order and initiate payment| 201 Created

GET| "/api/orders/{orderId}"| View order and payment status| 200 OK

GET| "/api/me/tickets"| View the authenticated user's tickets| 200 OK

DELETE| "/api/holds/{holdId}"| Release a seat hold| 204 No Content



Example: Browse events



Request:



GET /api/events?date=2026-12-20\&location=Nairobi



Example response:



{

&#x20; "events": \[

&#x20;   {

&#x20;     "id": 42,

&#x20;     "name": "Summer Music Festival",

&#x20;     "location": "Nairobi",

&#x20;     "date": "2026-12-20",

&#x20;     "availableSeats": 1200

&#x20;   }

&#x20; ]

}



Example: Hold seats



Request:



POST /api/events/42/holds

Content-Type: application/json



{

&#x20; "seatIds": \[101, 102]

}



Example response:



{

&#x20; "holdId": "hold\_abc123",

&#x20; "eventId": 42,

&#x20; "seatIds": \[101, 102],

&#x20; "status": "ACTIVE",

&#x20; "expiresAt": "2026-12-01T10:05:00Z"

}



The server must atomically claim every requested seat or reject the entire hold. A successful response means the seats are temporarily reserved, not yet purchased.



Example: Create an order



Request:



POST /api/orders

Idempotency-Key: unique-client-generated-key

Content-Type: application/json



{

&#x20; "holdId": "hold\_abc123",

&#x20; "paymentMethod": "provider\_checkout"

}



Example response:



{

&#x20; "orderId": "order\_789",

&#x20; "status": "PENDING\_PAYMENT",

&#x20; "paymentStatus": "PENDING"

}



The server validates that the hold belongs to the authenticated user and has not expired. Payment confirmation is processed through a trusted payment-provider callback or verified status check. The order is marked paid and tickets are issued only after confirmed payment.



Error responses



The API should return appropriate HTTP status codes:



\- "400 Bad Request": Invalid input or malformed request.

\- "401 Unauthorized": Missing or invalid authentication.

\- "403 Forbidden": The user is not permitted to access the resource.

\- "404 Not Found": Event, seat, hold, or order does not exist.

\- "409 Conflict": Seat is unavailable, a hold has expired, or a request conflicts with the current state.

\- "429 Too Many Requests": Rate limit exceeded.

\- "500 Internal Server Error": Unexpected server failure.



Example:



{

&#x20; "error": {

&#x20;   "code": "SEAT\_UNAVAILABLE",

&#x20;   "message": "One or more selected seats are no longer available."

&#x20; }

}



Payment and order-creation operations should support idempotency so that retrying a request does not create duplicate orders or charges.



4\. Data Model



TicketHub uses a relational database such as PostgreSQL because orders, payments, and seats require strong consistency and enforceable constraints.



Tables and columns



Users



Column| Type| Purpose

id| BIGINT| Primary key

name| VARCHAR(100)| Customer name

email| VARCHAR(255)| Unique email address

password\_hash| TEXT| Secure password hash

created\_at| TIMESTAMPTZ| Account creation time



Events



Column| Type| Purpose

id| BIGINT| Primary key

name| VARCHAR(200)| Event name

venue| VARCHAR(200)| Venue name

starts\_at| TIMESTAMPTZ| Event start time

status| VARCHAR(30)| Draft, published, or cancelled

created\_at| TIMESTAMPTZ| Record creation time



Seats



Column| Type| Purpose

id| BIGINT| Primary key

event\_id| BIGINT| Foreign key to events

seat\_number| VARCHAR(30)| Seat identifier

price| NUMERIC(10,2)| Ticket price

status| VARCHAR(20)| Available, held, or sold



Each seat belongs to one event. The combination of "event\_id" and "seat\_number" must be unique.



Orders



Column| Type| Purpose

id| BIGINT| Primary key

user\_id| BIGINT| Foreign key to users

status| VARCHAR(30)| Pending, paid, expired, or cancelled

total\_amount| NUMERIC(12,2)| Total order amount

idempotency\_key| VARCHAR(255)| Unique key for safe retries

created\_at| TIMESTAMPTZ| Order creation time



Order Items



Column| Type| Purpose

id| BIGINT| Primary key

order\_id| BIGINT| Foreign key to orders

seat\_id| BIGINT| Foreign key to seats

price\_at\_purchase| NUMERIC(10,2)| Price recorded for the order



A unique constraint on "seat\_id" in "order\_items" prevents the same seat from appearing in two orders. This is a permanent-sale constraint, not a temporary-hold mechanism.



Seat Holds



Column| Type| Purpose

id| BIGINT| Primary key

seat\_id| BIGINT| Foreign key to seats

user\_id| BIGINT| Foreign key to users

expires\_at| TIMESTAMPTZ| Hold expiration time

status| VARCHAR(20)| Active, converted, or released



Only one active hold may exist for a seat at a time. PostgreSQL can enforce this using a partial unique index on "seat\_id" where the status is "ACTIVE". Expired holds must be explicitly released or transitioned before a new hold is accepted; the passage of time alone does not remove an index entry.



Relationships



\- Users → Orders: One user can create many orders.

\- Events → Seats: One event has many seats.

\- Orders → Order Items: One order can contain multiple seats.

\- Seats → Order Items: A seat can appear in at most one completed sale.

\- Users → Seat Holds: One user can hold multiple seats temporarily.

\- Seats → Seat Holds: A seat can have at most one active hold.



Foreign keys enforce valid references. Unique constraints protect against duplicate seat assignments and duplicate idempotency keys.



How double-booking is prevented



The application must not rely only on a seat's displayed status or a prior availability check. Two customers could see the same seat as available at almost the same time.



Instead, TicketHub uses a transaction and database constraints:



1\. Start a database transaction.

2\. Lock the requested seat rows using "SELECT ... FOR UPDATE", in a consistent order.

3\. Verify that the seats belong to the event, are not sold, and do not have active holds.

4\. Create the holds and update the seat statuses within the transaction.

5\. Commit the transaction. If any seat cannot be claimed, roll back the entire multi-seat hold.



For example:



BEGIN;



SELECT id, status

FROM seats

WHERE event\_id = 42

&#x20; AND id IN (101, 102)

ORDER BY id

FOR UPDATE;



\-- Application checks availability while holding the row locks.

\-- Create holds and update seat states only if every seat is available.



COMMIT;



The comments describe application-side steps; this example is not a complete executable hold implementation.



Because competing transactions must wait for conflicting row locks, they cannot both successfully claim the same available seat. The unique constraints and partial unique index provide additional database-level protection.



When payment succeeds, the system converts the active hold into a sale and inserts the corresponding order items in a transaction. The permanent unique constraint on "order\_items.seat\_id" prevents two orders from selling the same seat. Expired holds must be released safely, and payment callbacks must be idempotent.



5\. Architecture



Architecture diagram



&#x20;                +------------------+

&#x20;                |   Web / Mobile   |

&#x20;                |      Client      |

&#x20;                +------------------+

&#x20;                          |

&#x20;                          v

&#x20;                +------------------+

&#x20;                |       DNS        |

&#x20;                +------------------+

&#x20;                          |

&#x20;                          v

&#x20;                +------------------+

&#x20;                |       CDN        |

&#x20;                | Static assets    |

&#x20;                +------------------+

&#x20;                          |

&#x20;                          v

&#x20;                +------------------+

&#x20;                | Load Balancer /  |

&#x20;                | Waiting Room     |

&#x20;                +------------------+

&#x20;                          |

&#x20;                          v

&#x20;                +------------------+

&#x20;                | API Application  |

&#x20;                | Servers (A, B, C)|

&#x20;                +------------------+

&#x20;                   |       |      |

&#x20;                   v       v      v

&#x20;               +------+ +------+ +-----------+

&#x20;               | Cache| | Queue| | Payment   |

&#x20;               |      | |      | | Provider  |

&#x20;               +------+ +------+ +-----------+

&#x20;                   |       |

&#x20;                   |       v

&#x20;                   |   +--------+

&#x20;                   |   | Workers|

&#x20;                   |   +--------+

&#x20;                   |       |

&#x20;                   v       v

&#x20;                +------------------+

&#x20;                | Primary Database |

&#x20;                | Transactions and |

&#x20;                | Seat Constraints |

&#x20;                +------------------+

&#x20;                          |

&#x20;                          v

&#x20;                +------------------+

&#x20;                | Read Replica(s)  |

&#x20;                +------------------+



The database remains the final authority for seat ownership. The waiting room controls access to expensive purchase operations, while browsing traffic can continue through separate read paths.



Component explanations



\- Client: Lets customers browse events, select seats, pay, and access tickets.

\- DNS: Resolves the TicketHub domain to the service endpoint.

\- CDN: Delivers static assets and reduces load on application servers.

\- Load balancer: Distributes requests among healthy application instances.

\- Waiting room: Controls how many customers enter the purchase flow at once and assigns queue positions or admission tokens.

\- Application servers: Authenticate customers, validate requests, enforce purchase rules, and coordinate database and payment operations.

\- Cache: Speeds up event pages and other read-heavy content. It must not be the authority for whether a seat can be sold.

\- Queue: Buffers background work and helps control the rate of downstream processing.

\- Workers: Process tasks such as email delivery, ticket generation, and expired-hold cleanup.

\- Primary database: Atomically manages seat holds, orders, and sales with transactions, locks, and constraints.

\- Read replicas: Serve suitable read-only queries, reducing load on the primary. Replica lag must be considered for availability displays.

\- Payment provider: Processes payments and sends verified status updates. TicketHub must safely handle retries and delayed callbacks.



How the system survives a big sale



1\. The waiting room places incoming customers into an orderly queue and admits a controlled number into checkout.

2\. CDN and cache services absorb much of the event-browsing traffic.

3\. Multiple application servers handle admitted customers, and additional instances can scale horizontally.

4\. Rate limits and admission controls protect the primary database from a sudden flood of seat-locking transactions.

5\. The database serializes conflicting seat claims and enforces unique constraints so that each seat is sold at most once.

6\. Seat holds expire after a defined period, allowing abandoned checkout seats to return to inventory.

7\. Payment callbacks and background tasks are processed idempotently, preventing repeated requests from issuing duplicate tickets.

8\. Health checks, monitoring, redundant application instances, backups, and database failover reduce downtime risk.



The system should clearly tell customers whether they are waiting, holding seats, paying, or confirmed. It must never report a successful purchase until the sale is durably recorded.



6\. Design Trade-Offs



Trade-off 1: Strong consistency vs. maximum throughput



Locking seat rows and using transactions protects correctness, but conflicting requests can wait and reduce throughput.



Decision: Use short database transactions and lock only the seats being purchased. Apply admission control during major sales. Correct seat ownership is more important than accepting unlimited concurrent checkout requests.



Trade-off 2: Fairness vs. checkout speed



A waiting room reduces overload and makes access more orderly, but it introduces waiting time and additional infrastructure.



Decision: Use a queue during high-demand sales and allow normal browsing without unnecessary waiting. Apply consistent queue rules, rate limits, and bot protection, and communicate expected wait states clearly.



Trade-off 3: Caching vs. fresh availability



Caching makes event pages faster, but seat availability can become stale.



Decision: Cache event descriptions and static content aggressively. Treat cached seat availability as informational only and confirm ownership through the primary database during the hold transaction.



Trade-off 4: Temporary holds vs. abandoned inventory



Seat holds protect customers while they pay, but customers who abandon checkout can temporarily prevent others from purchasing.



Decision: Use a short, clearly displayed hold expiration and release expired holds automatically. Do not release a seat while its payment is still being processed without checking the payment and order state.



Conclusion



TicketHub must be designed around three priorities: speed, fairness, and correctness. CDN caching and horizontal scaling improve performance, while a waiting room controls sudden demand. Database transactions, row locks, and unique constraints prevent double-booking. A reliable payment workflow ensures that tickets are issued only after confirmed payment and that retries do not create duplicate sales.

