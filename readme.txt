UIManagedDocument usage

1. No DB was created:
    - "configurePersistentStoreCoordinatorForURL" must create the file.
    - and also it must doing something with the cloud becuase some dubioud files are created in the cloud. 

2. Checking files are something different:
    - when a file is already exists, it may mean that the file is in cloud and in a sandbox.
    - so then why it complains about the reading should be in FileWrapper,
    - the writing should be NSDictionary type.

3. Do i have to block everything until the cloud works???
2011-07-23 12:51:31.475 iGeoJournal[9117:707] -[JournalViewController showSelectedButton], button is null. Setting default category
2011-07-23 12:51:31.587 iGeoJournal[9117:707] *** Terminating app due to uncaught exception 'NSRangeException', reason: '*** -[__NSArrayM objectAtIndex:]: index 0 beyond bounds for empty array'

::: This means that the database was empty or returns prematurely. But, then it shouldn't happen because the iCloud should be able to handle the local (or sandbox). 

4. When i delete the file in the cloud, it crashed in different place.
-[GeoJournalAppDelegate applicationDidFinishLaunching:], index: 0
-[NoteController viewDidLoad], controller: 0x382bc0
-[GeoDatabase persistentStoreCoordinator], db: file://localhost/var/mobile/Applications/1D31F7EF-FFB3-44E5-980C-E4EB81849714/Documents/GeoJournal.sqlite
[Switching to process 7939 thread 0x0]
__-[GeoDatabase persistentStoreCoordinator]_block_invoke_1, file://localhost/private/var/mobile/Library/Mobile%20Documents/WV3CVJV89H~com~odinasoftware~igeojournal/, /private/var/mobile/Library/Mobile Documents/WV3CVJV89H~com~odinasoftware~igeojournal/GeoJournal
-[GeoDatabase workaround_weakpackages_9653904:]
2011-07-23 12:54:31.838 iGeoJournal[9167:707] -[JournalViewController showSelectedButton], button is null. Setting default category

5. if 'persistentStoreCoordinator' is run in synchronously, it's not crashing at least.

6. Is this the file in the cloud.

-[GeoDatabase pollnewfiles_weakpackages:], filepath: /private/var/mobile/Library/Mobile Documents/WV3CVJV89H~com~odinasoftware~igeojournal/GeoJournal/.baseline/com.odinasoftware.igeojournal/baseline.store
-[GeoDatabase pollnewfiles_weakpackages:], filepath: /private/var/mobile/Library/Mobile Documents/WV3CVJV89H~com~odinasoftware~igeojournal/GeoJournal/.baseline/com.odinasoftware.igeojournal/meta.plist
-[GeoDatabase pollnewfiles_weakpackages:], filepath: /private/var/mobile/Library/Mobile Documents/WV3CVJV89H~com~odinasoftware~igeojournal/GeoJournal/mobile.00000000-0000-1000-8000-7CC5373053DA/com.odinasoftware.igeojournal/2.plist
-[GeoDatabase pollnewfiles_weakpackages:], filepath: /private/var/mobile/Library/Mobile Documents/WV3CVJV89H~com~odinasoftware~igeojournal/GeoJournal/mobile.00000000-0000-1000-8000-7CC5373053DA/com.odinasoftware.igeojournal/3.plist
-[GeoDatabase pollnewfiles_weakpackages:], filepath: /private/var/mobile/Library/Mobile Documents/WV3CVJV89H~com~odinasoftware~igeojournal/GeoJournal/.baseline/com.odinasoftware.igeojournal/baseline.gcmodel
-[GeoDatabase pollnewfiles_weakpackages:], filepath: /private/var/mobile/Library/Mobile Documents/WV3CVJV89H~com~odinasoftware~igeojournal/GeoJournal/.baseline/com.odinasoftware.igeojournal/baseline.model
-[GeoDatabase pollnewfiles_weakpackages:], filepath: /private/var/mobile/Library/Mobile Documents/WV3CVJV89H~com~odinasoftware~igeojournal/GeoJournal/mobile.00000000-0000-1000-8000-7CC5373053DA/com.odinasoftware.igeojournal/1.plist

7. Big question. :)
How to determine the files are synced or not? One file is one matter, but multiple files and database is totally different matter. 

8. What this error means?
-[GeoDatabase workaround_weakpackages_9653904:]
2011-07-26 07:08:26.940 iGeoJournal[818:707] CoreData: Ubiquity: Error, encountered empty log file at URL: file://localhost/private/var/mobile/Library/Mobile%20Documents/WV3CVJV89H~com~odinasoftware~igeojournal/GeoJournal/mobile.00000000-0000-1000-8000-7CC5373053DA/com.odinasoftware.igeojournal/1.plist
2011-07-26 07:08:26.948 iGeoJournal[818:707] CoreData: Ubiquity: Error, encountered empty log file at URL: file://localhost/private/var/mobile/Library/Mobile%20Documents/WV3CVJV89H~com~odinasoftware~igeojournal/GeoJournal/mobile.00000000-0000-1000-8000-7CC5373053DA/com.odinasoftware.igeojournal/2.plist
2011-07-26 07:08:26.954 iGeoJournal[818:707] CoreData: Ubiquity: Error, encountered empty log file at URL: file://localhost/private/var/mobile/Library/Mobile%20Documents/WV3CVJV89H~com~odinasoftware~igeojournal/GeoJournal/mobile.00000000-0000-1000-8000-7CC5373053DA/com.odinasoftware.igeojournal/3.plist
-[GeoDatabase persistentStoreCoordinator], returning, db: file://localhost/var/mobile/Applications/DC585B59-0A83-4C45-ADDC-346E81D5CE90/Documents/GeoJournal.sqlite
-[JournalViewController enumerateFilesAndSync]

9. After loading iphone, and then ipad
-[GeoJournalAppDelegate applicationDidFinishLaunching:], index: 0
-[NoteController viewDidLoad], controller: 0x3a9760
-[GeoDatabase persistentStoreCoordinator], file://localhost/private/var/mobile/Library/Mobile%20Documents/WV3CVJV89H~com~odinasoftware~igeojournal/, /private/var/mobile/Library/Mobile Documents/WV3CVJV89H~com~odinasoftware~igeojournal/GeoJournal
-[GeoDatabase workaround_weakpackages_9653904:]
2011-07-27 07:10:41.567 iGeoJournal[622:707] -[PFUbiquityBaseline existsInCloud](83): CoreData: Ubiquity:  Error attempting to read baseline: <PFUbiquityBaseline: 0x3da400>
ubiquityRootURL: file://localhost/private/var/mobile/Library/Mobile%20Documents/WV3CVJV89H~com~odinasoftware~igeojournal/GeoJournal
storeName: com.odinasoftware.igeojournal
baselineFileURL: file://localhost/private/var/mobile/Library/Mobile%20Documents/WV3CVJV89H~com~odinasoftware~igeojournal/GeoJournal/.baseline/com.odinasoftware.igeojournal/baseline.zip
.
Error: Error Domain=NSCocoaErrorDomain Code=256 "The operation couldn’t be completed. (Cocoa error 256 - The item failed to download.)" UserInfo=0x3dbd00 {NSURL=file://localhost/private/var/mobile/Library/Mobile%20Documents/WV3CVJV89H~com~odinasoftware~igeojournal/GeoJournal/.baseline/com.odinasoftware.igeojournal/baseline.zip, NSDescription=The item failed to download.}
-[GeoDatabase persistentStoreCoordinator], returning, db: file://localhost/var/mobile/Applications/DC585B59-0A83-4C45-ADDC-346E81D5CE90/Documents/GeoJournal.sqlite
-[JournalViewController enumerateFilesAndSync]
-[GeoDatabase journalByCategory:], journal array created.

10. After erasing the icloud data
-[GeoJournalAppDelegate applicationDidFinishLaunching:], index: 0
-[NoteController viewDidLoad], controller: 0x392650
-[GeoDatabase persistentStoreCoordinator], file://localhost/private/var/mobile/Library/Mobile%20Documents/WV3CVJV89H~com~odinasoftware~igeojournal/, /private/var/mobile/Library/Mobile Documents/WV3CVJV89H~com~odinasoftware~igeojournal/GeoJournal
-[GeoDatabase workaround_weakpackages_9653904:]
-[GeoDatabase persistentStoreCoordinator], returning, db: file://localhost/var/mobile/Applications/DC585B59-0A83-4C45-ADDC-346E81D5CE90/Documents/GeoJournal.sqlite
-[JournalViewController enumerateFilesAndSync]
-[GeoDatabase journalByCategory:], journal array created.

11. iPhone and then ipad again.
-[GeoJournalAppDelegate applicationDidFinishLaunching:], index: 0
-[NoteController viewDidLoad], controller: 0x3ac7d0
-[GeoDatabase persistentStoreCoordinator], file://localhost/private/var/mobile/Library/Mobile%20Documents/WV3CVJV89H~com~odinasoftware~igeojournal/, /private/var/mobile/Library/Mobile Documents/WV3CVJV89H~com~odinasoftware~igeojournal/GeoJournal
-[GeoDatabase workaround_weakpackages_9653904:]
-[GeoDatabase persistentStoreCoordinator], returning, db: file://localhost/var/mobile/Applications/DC585B59-0A83-4C45-ADDC-346E81D5CE90/Documents/GeoJournal.sqlite
-[JournalViewController enumerateFilesAndSync]
-[GeoDatabase journalByCategory:], journal array created.

