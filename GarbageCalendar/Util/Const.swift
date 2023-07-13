import Foundation
import UIKit

struct Const {
    
    //画面メッセージ
    static let locationViewMsg1 = "本アプリは位置情報を使用して、ゴミの情報を取得します"
    static let locationViewMsg2 = "位置情報を使用許可してください"
    static let locationViewMsg3 = "位置の取得が完了しました。"
    
    //APIのリクエスト先
    static let URL_API_CALL = "https://golira-pochette.com/GarbageAPI.php"
    static let URL_ZIPCODE_API = "https://zipcloud.ibsnet.co.jp/api/search?zipcode="
    static let API_KEY = "YOSUKE1227"
    
    //キー情報
    
    
    //処理タイプ
    static let TYPE_GET_USER_ID = "1"
    static let TYPE_REGIST_GARBAGE_INFO = "2"
    static let TYPE_REGIST_USER_INFO = "3"
    static let TYPE_GET_GARBAGE_AREA = "4"
    static let TYPE_GET_GARBAGE_INFO = "5"
    
    //画面番号
    static let LocationSetViewCode = "1"
    //画面制御用
    static let type_NumberPad = "1"
    
    //APIレスポンス用
    static let STATUS_SUCCSESS = "succsess"
    
    //エラー
    static let CODE_ERROR = 1
    static let CODE_NO_ERROR = 0
    
}
