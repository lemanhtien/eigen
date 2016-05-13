import Foundation
import Interstellar
import SwiftyJSON


typealias JWT = String
typealias StaticSaleResult = Result<(sale: LiveSale, jwt: JWT, bidderID: String)>


protocol LiveAuctionStaticDataFetcherType {
    func fetchStaticData() -> Observable<StaticSaleResult>
}

class LiveAuctionStaticDataFetcher: LiveAuctionStaticDataFetcherType {
    enum Error: ErrorType {
        case JSONParsing
    }

    let saleSlugOrID: String

    init(saleSlugOrID: String) {
        self.saleSlugOrID = saleSlugOrID
    }

    func fetchStaticData() -> Observable<StaticSaleResult> {
        let signal = Observable<StaticSaleResult>()

        ArtsyAPI.getLiveSaleStaticDataWithSaleID(saleSlugOrID,
            success: { data in
                let json = JSON(data)
                guard let
                    sale = self.parseSale(json),
                    jwt = self.parseJWT(json),
                    bidderID = self.parseBidderID(json) else {
                    return signal.update(.Error(Error.JSONParsing))
                }

                signal.update(.Success((sale: sale, jwt: jwt, bidderID: bidderID)))
            }, failure: { error in
                signal.update(.Error(error as ErrorType))
            })

        return signal
    }
    
}

extension LiveAuctionStaticDataFetcherType {

    func parseSale(json: JSON) -> LiveSale? {
        guard let saleJSON = json["data"]["sale"].dictionaryObject else { return nil }
        let sale = LiveSale(JSON: saleJSON)

        return sale
    }

    func parseJWT(json: JSON) -> JWT? {
        return json["data"]["causality_jwt"].string
    }

    func parseBidderID(json: JSON) -> String? {
        return json["data"]["me"]["paddle_number"].string
    }

}