/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A class that used to mimic fetching data asynchronously.
*/

import Foundation

/// - Tag: AsyncFetcher
class AsyncFetcher {
    // MARK: Types

    /// A serial `OperationQueue` to lock access to the `fetchQueue` and `completionHandlers` properties.
//    private let serialAccessQueue = OperationQueue()

    /// An `OperationQueue` that contains `AsyncFetcherOperation`s for requested data.
    private let fetchQueue = OperationQueue()

    /// An `NSCache` used to store fetched objects.
    private var cache = NSCache<NSUUID, DisplayData>()

    // MARK: Initialization

    init() {
//        serialAccessQueue.maxConcurrentOperationCount = 1
    }

    // MARK: Object fetching

    /**
     Asynchronously fetches data for a specified `UUID`.
     
     - Parameters:
         - identifier: The `UUID` to fetch data for.
         - completion: An optional called when the data has been fetched.
    */
    func fetchAsync(_ identifier: UUID, completion: ((DisplayData?) -> Void)? = nil) {
        
        if let data = fetchedData(for: identifier) {
            // The object has already been cached; call the completion handler with that object.
            if let completion = completion {
                completion(data)
            }
        } else {
            // Enqueue a request for the object.
            let operation = AsyncFetcherOperation(identifier: identifier)
            
            // Set the operation's completion block to cache the fetched object and call the associated completion blocks.
            operation.completionBlock = { [weak operation] in
                guard let fetchedData = operation?.fetchedData else { return }
                self.cache.setObject(fetchedData, forKey: identifier as NSUUID)
                
                if let completion = completion {
                    completion(fetchedData)
                }
            }
            
            fetchQueue.addOperation(operation)
        }
    }

    /**
     Returns the previously fetched data for a specified `UUID`.
     
     - Parameter identifier: The `UUID` of the object to return.
     - Returns: The 'DisplayData' that has previously been fetched or nil.
     */
    func fetchedData(for identifier: UUID) -> DisplayData? {
        return cache.object(forKey: identifier as NSUUID)
    }

    /**
     Cancels any enqueued asychronous fetches for a specified `UUID`. Completion
     handlers are not called if a fetch is canceled.
     
     - Parameter identifier: The `UUID` to cancel fetches for.
     */
    func cancelFetch(_ identifier: UUID) {
        self.fetchQueue.isSuspended = true
        defer {
            self.fetchQueue.isSuspended = false
        }

        self.operation(for: identifier)?.cancel()
    }

    // MARK: Convenience

    /**
     Returns any enqueued `ObjectFetcherOperation` for a specified `UUID`.
     
     - Parameter identifier: The `UUID` of the operation to return.
     - Returns: The enqueued `ObjectFetcherOperation` or nil.
     */
    private func operation(for identifier: UUID) -> AsyncFetcherOperation? {
        for case let fetchOperation as AsyncFetcherOperation in fetchQueue.operations
            where !fetchOperation.isCancelled && fetchOperation.identifier == identifier {
            return fetchOperation
        }
        
        return nil
    }

}
