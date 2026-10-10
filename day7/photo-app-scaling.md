Day 7 Assignment: Scaling a Photo-Sharing App



1\. Assumptions



SnapShare has 10 million registered users, and 10% are active daily.



\- Registered users: 10,000,000

\- Daily active users (DAU): 10,000,000 × 10% = 1,000,000 users

\- Each daily active user uploads 1 photo per day.

\- Each daily active user views 50 feed pages per day.

\- Average original photo size: 2 MB.

\- Each photo also has one thumbnail of 50 KB.

\- A year has 365 days.

\- For average request rates, assume activity is spread across 24 hours (86,400 seconds per day).

\- Peak feed traffic is estimated at 5 times the average rate.

\- For storage estimates, use decimal units: 1 MB = 1,000 KB and 1 TB = 1,000,000 MB.

\- The estimates exclude database overhead, backups, replication overhead, and additional copies of photos.



2\. Traffic and Storage Calculations



Daily active users



10,000,000 registered users × 0.10 = 1,000,000 daily active users.



Uploads per second



Each daily active user uploads one photo per day.



\- Daily uploads: 1,000,000 × 1 = 1,000,000 photos

\- Average uploads per second: 1,000,000 ÷ 86,400 = 11.57 uploads/second



This is an average; actual upload traffic may be higher during busy periods.



Feed views per second



Each daily active user views 50 feed pages per day.



\- Daily feed views: 1,000,000 × 50 = 50,000,000 feed pages

\- Average feed views per second: 50,000,000 ÷ 86,400 = 578.70 feed views/second

\- Peak feed views per second: 578.70 × 5 = 2,893.52 feed views/second



The design should therefore handle approximately 2,894 feed requests per second at the estimated peak, before allowing for additional headroom.



Photo storage per year



Original photo storage:



\- Daily original storage: 1,000,000 × 2 MB = 2,000,000 MB = 2 TB

\- Annual original storage: 2 TB × 365 = 730 TB/year



Thumbnail storage:



\- Daily thumbnail storage: 1,000,000 × 50 KB = 50,000,000 KB = 50 GB

\- Annual thumbnail storage: 50 GB × 365 = 18.25 TB/year



Total new photo and thumbnail storage:



730 TB + 18.25 TB = 748.25 TB/year, or approximately 0.75 PB/year.



These figures represent new files generated each year. Total retained storage will grow across years if old photos are not deleted. Real capacity requirements will also be higher if the system keeps multiple copies, versions, or backups.



3\. Is SnapShare Read-Heavy or Write-Heavy?



SnapShare is read-heavy because users generate 50 million feed views per day but only 1 million photo uploads per day. That is approximately 50 feed views for every upload.



The architecture should prioritize fast feed delivery using a CDN, caching, and database read replicas. Uploads must still be reliable, but frequently requested feed data and image files should be served without repeatedly querying the primary database or transferring every image from an application server.



4\. Why Photos Should Not Be Stored Inside the Database



Original photos and thumbnails should be stored in object storage, while the database stores metadata such as photo ID, owner ID, object-storage key, caption, upload time, and visibility settings.



Storing large image files directly in database rows would increase database size, backups, and transfer overhead. Object storage is designed to store large files efficiently and can work with a CDN to deliver images close to users. The database remains focused on structured data, relationships, and queries.



5\. Architecture Diagram



&#x20;                        +------------------+

&#x20;                        |      Users       |

&#x20;                        +--------+---------+

&#x20;                                 |

&#x20;                +----------------+----------------+

&#x20;                |                                 |

&#x20;                v                                 v

&#x20;       +------------------+              +------------------+

&#x20;       |       CDN        |              |  Load Balancer   |

&#x20;       | Cached images    |              +--------+---------+

&#x20;       +--------+---------+                       |

&#x20;                |                                 v

&#x20;                |                      +----------------------+

&#x20;                |                      |    App Servers       |

&#x20;                |                      | Feed / Upload API    |

&#x20;                |                      +----+-----+-----+-----+

&#x20;                |                           |     |     |

&#x20;                |                     +-----+     |     +----------+

&#x20;                |                     |           |                |

&#x20;                |                     v           v                v

&#x20;                |              +-------------+ +-----------+ +-------------+

&#x20;                |              | Cache       | | Primary   | | Object      |

&#x20;                |              | Feed data   | | Database  | | Storage     |

&#x20;                |              +-------------+ +-----+-----+ | Originals \& |

&#x20;                |                                    |       | thumbnails  |

&#x20;                |                                    v       +------+------+

&#x20;                |                             +-------------+        |

&#x20;                |                             | Read Replica|        |

&#x20;                |                             +-------------+        |

&#x20;                |                                                    |

&#x20;                |                    +------------------+            |

&#x20;                |                    | Message Queue    |            |

&#x20;                |                    | Thumbnail jobs   |            |

&#x20;                |                    +--------+---------+            |

&#x20;                |                             |                      |

&#x20;                |                             v                      |

&#x20;                |                    +------------------+            |

&#x20;                |                    | Thumbnail Worker |------------+

&#x20;                |                    +------------------+  Writes

&#x20;                |                                          thumbnail

&#x20;                +------------------------------------------ delivery



6\. What Each Component Solves



\- CDN: Delivers cached images and thumbnails from locations near users, reducing latency and origin-server bandwidth.

\- Load balancer: Distributes incoming API requests across healthy application servers so that one server does not become a bottleneck.

\- Application servers: Authenticate users and handle feed requests, photo-upload coordination, metadata, and business logic.

\- Cache: Keeps frequently requested feed data and other hot metadata in fast memory, reducing repeated database queries.

\- Primary database: Stores authoritative structured data such as users, follows, photo metadata, and permissions, and handles writes.

\- Read replica: Serves eligible read queries to reduce load on the primary database, with the possibility of replication lag.

\- Object storage: Stores original photos and generated thumbnails durably without filling database rows with large binary files.

\- Message queue: Holds thumbnail-generation jobs so uploads can complete without waiting for image processing.

\- Thumbnail worker: Consumes queued jobs, creates appropriately sized thumbnails, and writes them to object storage for later CDN delivery.



7\. Photo Upload Flow



1\. A user selects a photo and submits it through the SnapShare upload interface.

2\. The application server authenticates the user and checks file type, size limits, and upload permissions.

3\. The server creates a photo record or upload session and determines the object-storage key for the original file.

4\. The photo is uploaded to object storage, directly or through a short-lived pre-signed upload URL.

5\. After successful upload, the system confirms that the object exists and records or updates the photo metadata in the primary database.

6\. The application publishes a thumbnail-generation job to the message queue.

7\. The user receives an upload confirmation without having to wait for thumbnail processing to finish.

8\. A thumbnail worker consumes the job, reads the original photo, validates and processes it, and creates a 50 KB thumbnail target.

9\. The worker saves the thumbnail to object storage and updates the photo's processing status in the database.

10\. The CDN serves the original or thumbnail to viewers using the relevant object URL or cache key. Cache invalidation or versioned URLs are used when an image changes.



The system should handle failed jobs through retries and a dead-letter queue, and should avoid creating duplicate thumbnail results when a job is retried.



8\. Trade-Offs



Trade-off 1: Cache speed versus freshness



Caching feed data improves performance and reduces database load, but cached feeds can become stale when a user uploads a photo or follows someone new. The system needs a cache expiration or invalidation strategy, balancing freshness against speed.



Trade-off 2: Asynchronous thumbnails versus immediate availability



A message queue allows the upload to finish quickly while thumbnail generation happens in the background. However, a thumbnail may not be ready immediately, so the interface needs a processing state or a temporary original-image fallback.



Trade-off 3: Read replicas versus consistency



Read replicas increase read capacity and reduce primary-database pressure. However, replication lag can mean that a newly uploaded photo does not appear immediately in a feed served from a replica. The application may temporarily read recent changes from the primary database when stronger read-after-write consistency is needed.



Trade-off 4: Object storage and CDN versus operational complexity



Object storage and a CDN scale image storage and delivery more efficiently than serving every image through application servers. However, they add configuration, access-control, cache-invalidation, and storage-cost considerations. Private photos require authorization-aware delivery, such as short-lived signed URLs.



9\. Conclusion



SnapShare has an estimated 1 million daily active users, 11.57 uploads per second on average, and approximately 579 feed views per second on average, rising to about 2,894 at the estimated peak. New original photos and thumbnails add approximately 748.25 TB of storage per year before backups and extra copies.



Because the workload is read-heavy, the design uses a CDN, a cache, horizontally scalable application servers, and a database read replica to serve traffic efficiently. Object storage holds image files, while a queue and thumbnail workers process images asynchronously to keep uploads responsive.

