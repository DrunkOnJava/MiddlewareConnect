import Foundation
import CloudKit

/// Manager for handling iCloud storage
class CloudStorageManager {
    // MARK: - Singleton
    
    /// Shared instance
    static let shared = CloudStorageManager()
    
    // MARK: - Properties
    
    /// The iCloud container
    private let container: CKContainer
    
    /// The private database
    private let privateDatabase: CKDatabase
    
    /// The shared database
    private let sharedDatabase: CKDatabase
    
    /// The public database
    private let publicDatabase: CKDatabase
    
    /// Whether iCloud is available
    private(set) var isAvailable = false
    
    /// The account status
    private(set) var accountStatus: CKAccountStatus = .couldNotDetermine
    
    /// The subscription ID for changes
    private let subscriptionID = "com.yourcompany.llmbuddy.changes"
    
    // MARK: - Initialization
    
    private init() {
        // Initialize the container
        container = CKContainer(identifier: "iCloud.com.yourcompany.llmbuddy")
        
        // Get the databases
        privateDatabase = container.privateCloudDatabase
        sharedDatabase = container.sharedCloudDatabase
        publicDatabase = container.publicCloudDatabase
        
        // Check if iCloud is available
        checkAvailability()
    }
    
    // MARK: - Public Methods
    
    /// Checks if iCloud is available
    /// - Parameter completion: The completion handler
    func checkAvailability(completion: ((Bool) -> Void)? = nil) {
        container.accountStatus { [weak self] status, error in
            guard let self = self else { return }
            
            self.accountStatus = status
            
            switch status {
            case .available:
                self.isAvailable = true
                completion?(true)
            default:
                self.isAvailable = false
                completion?(false)
            }
        }
    }
    
    /// Sets up the subscription for changes
    /// - Parameter completion: The completion handler
    func setupSubscription(completion: @escaping (Bool, Error?) -> Void) {
        // Check if the subscription already exists
        let predicate = NSPredicate(format: "subscriptionID == %@", subscriptionID)
        let query = CKQuery(recordType: "CKSubscription", predicate: predicate)
        
        privateDatabase.perform(query, inZoneWith: nil) { [weak self] records, error in
            guard let self = self else { return }
            
            if let error = error {
                completion(false, error)
                return
            }
            
            if let records = records, !records.isEmpty {
                // Subscription already exists
                completion(true, nil)
                return
            }
            
            // Create the subscription
            let subscription = CKQuerySubscription(
                recordType: "Document",
                predicate: NSPredicate(value: true),
                subscriptionID: self.subscriptionID,
                options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion]
            )
            
            // Create the notification info
            let notificationInfo = CKSubscription.NotificationInfo()
            notificationInfo.shouldSendContentAvailable = true
            subscription.notificationInfo = notificationInfo
            
            // Save the subscription
            self.privateDatabase.save(subscription) { _, error in
                if let error = error {
                    completion(false, error)
                } else {
                    completion(true, nil)
                }
            }
        }
    }
    
    /// Saves a document to iCloud
    /// - Parameters:
    ///   - document: The document to save
    ///   - completion: The completion handler
    func saveDocument(_ document: CloudDocument, completion: @escaping (Bool, Error?) -> Void) {
        // Check if iCloud is available
        guard isAvailable else {
            completion(false, CloudStorageError.iCloudNotAvailable)
            return
        }
        
        // Create the record
        let record = CKRecord(recordType: "Document")
        
        // Set the record values
        record["name"] = document.name as CKRecordValue
        record["type"] = document.type.rawValue as CKRecordValue
        record["data"] = document.data as CKRecordValue
        record["createdAt"] = document.createdAt as CKRecordValue
        record["updatedAt"] = document.updatedAt as CKRecordValue
        
        // Save the record
        privateDatabase.save(record) { savedRecord, error in
            if let error = error {
                completion(false, error)
            } else if let savedRecord = savedRecord {
                // Update the document with the record ID
                var updatedDocument = document
                updatedDocument.recordID = savedRecord.recordID
                
                completion(true, nil)
            } else {
                completion(false, CloudStorageError.unknownError)
            }
        }
    }
    
    /// Updates a document in iCloud
    /// - Parameters:
    ///   - document: The document to update
    ///   - completion: The completion handler
    func updateDocument(_ document: CloudDocument, completion: @escaping (Bool, Error?) -> Void) {
        // Check if iCloud is available
        guard isAvailable else {
            completion(false, CloudStorageError.iCloudNotAvailable)
            return
        }
        
        // Check if the document has a record ID
        guard let recordID = document.recordID else {
            completion(false, CloudStorageError.documentNotFound)
            return
        }
        
        // Fetch the record
        privateDatabase.fetch(withRecordID: recordID) { [weak self] record, error in
            guard let self = self else { return }
            
            if let error = error {
                completion(false, error)
                return
            }
            
            guard var record = record else {
                completion(false, CloudStorageError.documentNotFound)
                return
            }
            
            // Update the record values
            record["name"] = document.name as CKRecordValue
            record["type"] = document.type.rawValue as CKRecordValue
            record["data"] = document.data as CKRecordValue
            record["updatedAt"] = document.updatedAt as CKRecordValue
            
            // Save the record
            self.privateDatabase.save(record) { savedRecord, error in
                if let error = error {
                    completion(false, error)
                } else if savedRecord != nil {
                    completion(true, nil)
                } else {
                    completion(false, CloudStorageError.unknownError)
                }
            }
        }
    }
    
    /// Deletes a document from iCloud
    /// - Parameters:
    ///   - document: The document to delete
    ///   - completion: The completion handler
    func deleteDocument(_ document: CloudDocument, completion: @escaping (Bool, Error?) -> Void) {
        // Check if iCloud is available
        guard isAvailable else {
            completion(false, CloudStorageError.iCloudNotAvailable)
            return
        }
        
        // Check if the document has a record ID
        guard let recordID = document.recordID else {
            completion(false, CloudStorageError.documentNotFound)
            return
        }
        
        // Delete the record
        privateDatabase.delete(withRecordID: recordID) { recordID, error in
            if let error = error {
                completion(false, error)
            } else if recordID != nil {
                completion(true, nil)
            } else {
                completion(false, CloudStorageError.unknownError)
            }
        }
    }
    
    /// Fetches all documents from iCloud
    /// - Parameter completion: The completion handler
    func fetchAllDocuments(completion: @escaping ([CloudDocument]?, Error?) -> Void) {
        // Check if iCloud is available
        guard isAvailable else {
            completion(nil, CloudStorageError.iCloudNotAvailable)
            return
        }
        
        // Create the query
        let query = CKQuery(recordType: "Document", predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
        
        // Perform the query
        privateDatabase.perform(query, inZoneWith: nil) { records, error in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let records = records else {
                completion([], nil)
                return
            }
            
            // Convert the records to documents
            let documents = records.compactMap { record -> CloudDocument? in
                guard let name = record["name"] as? String,
                      let typeString = record["type"] as? String,
                      let type = CloudDocumentType(rawValue: typeString),
                      let data = record["data"] as? Data,
                      let createdAt = record["createdAt"] as? Date,
                      let updatedAt = record["updatedAt"] as? Date else {
                    return nil
                }
                
                return CloudDocument(
                    recordID: record.recordID,
                    name: name,
                    type: type,
                    data: data,
                    createdAt: createdAt,
                    updatedAt: updatedAt
                )
            }
            
            completion(documents, nil)
        }
    }
    
    /// Fetches a document from iCloud
    /// - Parameters:
    ///   - recordID: The record ID of the document
    ///   - completion: The completion handler
    func fetchDocument(withRecordID recordID: CKRecord.ID, completion: @escaping (CloudDocument?, Error?) -> Void) {
        // Check if iCloud is available
        guard isAvailable else {
            completion(nil, CloudStorageError.iCloudNotAvailable)
            return
        }
        
        // Fetch the record
        privateDatabase.fetch(withRecordID: recordID) { record, error in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let record = record else {
                completion(nil, CloudStorageError.documentNotFound)
                return
            }
            
            // Convert the record to a document
            guard let name = record["name"] as? String,
                  let typeString = record["type"] as? String,
                  let type = CloudDocumentType(rawValue: typeString),
                  let data = record["data"] as? Data,
                  let createdAt = record["createdAt"] as? Date,
                  let updatedAt = record["updatedAt"] as? Date else {
                completion(nil, CloudStorageError.invalidDocument)
                return
            }
            
            let document = CloudDocument(
                recordID: record.recordID,
                name: name,
                type: type,
                data: data,
                createdAt: createdAt,
                updatedAt: updatedAt
            )
            
            completion(document, nil)
        }
    }
    
    /// Shares a document with another user
    /// - Parameters:
    ///   - document: The document to share
    ///   - emailAddress: The email address of the user to share with
    ///   - completion: The completion handler
    func shareDocument(_ document: CloudDocument, withEmailAddress emailAddress: String, completion: @escaping (Bool, Error?) -> Void) {
        // Check if iCloud is available
        guard isAvailable else {
            completion(false, CloudStorageError.iCloudNotAvailable)
            return
        }
        
        // Check if the document has a record ID
        guard let recordID = document.recordID else {
            completion(false, CloudStorageError.documentNotFound)
            return
        }
        
        // Fetch the record
        privateDatabase.fetch(withRecordID: recordID) { [weak self] record, error in
            guard let self = self else { return }
            
            if let error = error {
                completion(false, error)
                return
            }
            
            guard let record = record else {
                completion(false, CloudStorageError.documentNotFound)
                return
            }
            
            // Look up the user
            self.container.discoverUserIdentity(withEmailAddress: emailAddress) { identity, error in
                if let error = error {
                    completion(false, error)
                    return
                }
                
                guard let identity = identity else {
                    completion(false, CloudStorageError.userNotFound)
                    return
                }
                
                // Create the share
                let share = CKShare(rootRecord: record)
                share[CKShare.SystemFieldKey.title] = document.name as CKRecordValue
                
                // Save the share
                self.privateDatabase.save(share) { _, error in
                    if let error = error {
                        completion(false, error)
                    } else {
                        // Add the user to the share
                        share.addParticipant(CKShare.Participant(userIdentity: identity, permission: .readWrite))
                        
                        // Save the updated share
                        self.privateDatabase.save(share) { _, error in
                            if let error = error {
                                completion(false, error)
                            } else {
                                completion(true, nil)
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// Resolves a conflict between two documents
    /// - Parameters:
    ///   - clientDocument: The client document
    ///   - serverDocument: The server document
    /// - Returns: The resolved document
    func resolveConflict(clientDocument: CloudDocument, serverDocument: CloudDocument) -> CloudDocument {
        // In a real app, you would implement a more sophisticated conflict resolution strategy
        // For now, we'll just use the most recently updated document
        
        if clientDocument.updatedAt > serverDocument.updatedAt {
            return clientDocument
        } else {
            return serverDocument
        }
    }
}

// MARK: - Cloud Document

/// A document stored in iCloud
struct CloudDocument {
    /// The record ID of the document
    var recordID: CKRecord.ID?
    
    /// The name of the document
    let name: String
    
    /// The type of the document
    let type: CloudDocumentType
    
    /// The data of the document
    let data: Data
    
    /// The date the document was created
    let createdAt: Date
    
    /// The date the document was last updated
    let updatedAt: Date
    
    /// Creates a new document
    /// - Parameters:
    ///   - name: The name of the document
    ///   - type: The type of the document
    ///   - data: The data of the document
    /// - Returns: A new document
    static func create(name: String, type: CloudDocumentType, data: Data) -> CloudDocument {
        let now = Date()
        
        return CloudDocument(
            recordID: nil,
            name: name,
            type: type,
            data: data,
            createdAt: now,
            updatedAt: now
        )
    }
    
    /// Creates an updated version of the document
    /// - Parameters:
    ///   - name: The new name of the document
    ///   - data: The new data of the document
    /// - Returns: An updated document
    func updated(name: String? = nil, data: Data? = nil) -> CloudDocument {
        return CloudDocument(
            recordID: recordID,
            name: name ?? self.name,
            type: type,
            data: data ?? self.data,
            createdAt: createdAt,
            updatedAt: Date()
        )
    }
}

// MARK: - Cloud Document Type

/// The type of a cloud document
enum CloudDocumentType: String {
    /// A text document
    case text
    
    /// A PDF document
    case pdf
    
    /// A CSV document
    case csv
    
    /// An image document
    case image
    
    /// A settings document
    case settings
}

// MARK: - Cloud Storage Error

/// Errors that can occur during cloud storage operations
enum CloudStorageError: Error {
    /// iCloud is not available
    case iCloudNotAvailable
    
    /// The document was not found
    case documentNotFound
    
    /// The document is invalid
    case invalidDocument
    
    /// The user was not found
    case userNotFound
    
    /// An unknown error occurred
    case unknownError
}

// MARK: - Error Localization

extension CloudStorageError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .iCloudNotAvailable:
            return "iCloud is not available. Please sign in to your iCloud account in Settings."
        case .documentNotFound:
            return "The document was not found."
        case .invalidDocument:
            return "The document is invalid."
        case .userNotFound:
            return "The user was not found."
        case .unknownError:
            return "An unknown error occurred."
        }
    }
}
