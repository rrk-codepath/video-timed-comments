

import FTIndicator

extension FTIndicator {
    
    static func dismissProgressOnMainThread() {
        DispatchQueue.main.async(execute: {
            FTIndicator.dismissProgress()
        })
    }
}
