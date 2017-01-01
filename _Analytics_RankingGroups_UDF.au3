;_Analytics_RankingGroups.au3
#include-once
#include <array.au3>
#include <string.au3>
#include <Inet.au3>
#include "JSON.au3"

#cs INFO
Analytics Ranking Group
Coded by Trojan Nguyen (fb.co/trojan.nguyen.103)
#ce
_XulyRank()
; #FUNCTION# ====================================================================================================================
; Name ..........: _XulyRank
; Description ...: Tiền hành chạy hệ thống
; Syntax ........: _XulyRank()
; Author ........: Trojan Nguyen
; ===============================================================================================================================_XulyRank()
Func _XulyRank()
	Global $Array2d[0][3]
	Local $access_token, $LimitTime, $ngay, $tuan, $thang, $id_group, $link, $i
	$access_token= "Token của bạn"
	$LimitTime =  _DateDiff('s', "1970/01/01 00:00:00", _NowCalc()) ; Lấy time hiện tại (convert to seconds)
	$ngay = 86400 ; tổng giây một ngày
	$tuan = 604800 ; tổng giây một tuần
	$thang = 2592000 ; tổng giây một tháng
	$id_group = "";Vd : 364997627165697 (J2team)
	$link = "https://graph.facebook.com/v2.8/"&$id_group&"/feed?fields=from,updated_time&access_token="&$access_token
	_GetPost2($access_token, $link, $LimitTime-$thang)
	_ArraySort($Array2d,1,0,0,1)
	_ArrayDisplay($Array2d)
	FOr $i=0 to UBound($Array2d, 1)-1 
		$Array2d[$i][2] = _GetName($Array2d[$i][0], $access_token)
		ConsoleWrite($Array2d[$i][2]&@CRLF)
	Next
	_ArrayDisplay($Array2d)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name ..........: _GetName
; Description ...: Lấy tên từ id
; Syntax ........: _GetName($id, $access_token)
; Parameters ....: $id                  - id cần lấy tên.
;                  $access_token        - Access token.
; Return values .: Success : Trả về tên người dùng
;                  Failure : @error set về 0
; Author ........: Trojan Nguyen
; ===============================================================================================================================
Func _GetName($id, $access_token)
	If $id="" or $access_token="" then Return SetError(1,0,0)
	Local $link, $JsonObj, $name
	$link = "https://graph.facebook.com/v2.8/"&$id&"?access_token=" & $access_token
	$JsonObj = Json_Decode(_INetGetSource($link))
	$name = Json_Get($JsonObj, '["name"]')
	Return $name
EndFunc

; #FUNCTION# ====================================================================================================================
; Name ..........: _GetPost2
; Description ...: Hàm chạy Add User và Hệ thống Ranking
; Syntax ........: _GetPost2($access_token, ByRef $link, $LimitTime)
; Parameters ....: $access_token        - Access Token.
;                  ByRef $link          - Link Json (Sẽ thay đổi liên tục trong quá trình gọi đệ quy).
;                  $LimitTime           - Thời gian kiểm soát (vd : 1 ngày, 1 tuần, 1 tháng,...) - đổi sang giây.
; Return values .: Success : Trả về 1, và lấy giá trị trong mảng $Array2d 2 chiều
;                  Failure : @error set về 0
; Author ........: Trojan Nguyen
; ===============================================================================================================================
Func _GetPost2($access_token,ByRef $link, $LimitTime)
	Local $JsonObj, $i, $point, $actor_id, $post_id, $sharecount, $linkReactions, $j, $tam, $linkCMT, $updated_time
	$JsonObj = Json_Decode(_INetGetSource($link))
;~ 	If @error then Return SetError(1,0,0)
	$i = 0
	While 1
		$point = 0
		$updated_time = Json_Get($JsonObj, '["data"][' & $i & ']["updated_time"]')
		If @error then ExitLoop
		If _FOrmatTime($updated_time)<$LimitTime Then ExitLoop
		$actor_id = Json_Get($JsonObj, '["data"][' & $i & ']["from"]["id"]')
		If @error then ExitLoop
		$point += 3
		$post_id = Json_Get($JsonObj, '["data"][' & $i & ']["id"]')
		If @error then ExitLoop
		ConsoleWrite($post_id&@CRLF)
		$sharecount = _GetShare($post_id, $access_token)
		If $sharecount <> False then $point += $sharecount
		$linkReactions = "https://graph.facebook.com/v2.8/"&$post_id&"/reactions?limit=25&access_token="&$access_token
		Global $Array[0]
;~ 		MsgBox
		_GetReactions($linkReactions)
		If Not IsArray($Array) Then
			_ArrayAdd($Array2d, $actor_id&"|1") ; Nếu không có ai like, sẽ tự động tăng điểm +1 cho người đăng bài
		Else
			$point += Ubound($Array) ; Tăng điểm cho người đăng bài dựa trên số lượng like
		EndIf
		
		; LỌc Trùng Sau khi thêm REactions
		For $j = 0 To (UBound($Array)-1)
			$tam = _ArrayFindAll($Array2d, $Array[$j], Default, Default, Default, Default, 0); Lọc Trùng của ID Người like trong Danh Sách Ranking
			If UBound($tam)>=1 Then
				$Array2d[$tam[0]][1] += 1; Nếu trùng thì cộng dồn điểm cho user id (+1)
			Else
				_ArrayAdd($Array2d, $Array[$j]&"|1")	; Nếu không có trùng thì tạo user id mới cho Array
			EndIf
		Next
		
		$linkCMT = "https://graph.facebook.com/v2.8/"&$post_id&"?fields=comments&access_token="&$access_token
		Global $ArrayCMT[0]
		_GetCMT($linkCMT)
		
		If Not IsArray($ArrayCMT) Then
			_ArrayAdd($Array2d, $actor_id&"|1")	 ;Nếu không có ai cmt, sẽ tự động tăng điểm +1 cho người đăng bài
		Else
			$point += Ubound($ArrayCMT);Tăng điểm cho người đăng bài dựa trên số lượng cmt
		EndIf
		
		For $j = 0 To (UBound($ArrayCMT)-1)
			$tam = _ArrayFindAll($Array2d, $ArrayCMT[$j], Default, Default, Default, Default, 0);Lọc Trùng của ID Người CMT trong Danh Sách Ranking
			If UBound($tam)>=1 Then
				$Array2d[$tam[0]][1] += 1; Nếu trùng thì cộng dồn điểm cho user id (+1)
			Else
				_ArrayAdd($Array2d, $ArrayCMT[$j]&"|1")	;Nếu không có trùng thì tạo user id mới cho Array 
			EndIf
		Next
		
		
		; Lọc Trùng để thêm vào danh sách Ranking đối với người đăng bài
		$tam = _ArrayFindAll($Array2d, $actor_id, Default, Default, Default, Default, 0) ; Kiểm tra xem id người đăng bài có trong danh sách Ranking hay không?
		If UBound($tam)=1 Then
			$Array2d[$tam[0]][1] += $point ;  Nếu trùng thì cộng dồn điểm
		Else
			_ArrayAdd($Array2d, $actor_id&"|"&$point);Nếu không trùng thì tạo user id
		EndIf
		$updated_time = Json_Get($JsonObj, '["data"][' & $i & ']["updated_time"]') ; Lấy Update time để kiểm tra Limit Time
		$i += 1
	WEnd
	If _FOrmatTime($updated_time)<$LimitTime Then
		Return 1
	Else
		$updated_time = Json_Get($JsonObj, '["data"][' & $i-1 & ']["updated_time"]')
		If @error then Return SetError(1,0,0)
		If $updated_time<=$LimitTime Then
			Return 1
		Else
			$link = Json_Get($JsonObj, '["paging"]["next"]'); Lấy link kế tiếp của api để get tiếp
			If $link<>"" then 
				_GetPost2($access_token, $link, $LimitTime) ; Gọi đệ quy để cộng dồn
			Else
				Return 1
			EndIf
		EndIf
	EndIf
EndFunc

; #FUNCTION# ====================================================================================================================
; Name ..........: _FOrmatTime
; Description ...: Format Time của Api Facebook thành giây
; Syntax ........: _FOrmatTime($string)
; Parameters ....: $string              - String Time.
; Return values .: Success : Trả về giây
;                  Failure : @error set về 0
; Author ........: Trojan Nguyen
; ===============================================================================================================================
FUnc _FOrmatTime($string)
	IF $string="" then SetError(1,0,0)
	Local $time
	$string = StringReplace($string, "T", " ")    ;
	$string = StringReplace($string, "+0000", "") ;  XÓA BỎ CÁC KÝ TỰ KHÔNG CẦN THIẾT (múi giờ,...)
	$string = StringReplace($string, "-", "/")    ;
	$time = _DateDiff('s', "1970/01/01 00:00:00", $string)
	Return $time
EndFunc

; #FUNCTION# ====================================================================================================================
; Name ..........: _GetReactions
; Description ...: Lấy user like từ ID Post
; Syntax ........: _GetReactions(ByRef $link)
; Parameters ....: ByRef $link          - Link.
; Return values .: Success : Trả về danh sach ID user Like
;                  Failure : @error set về 0
; Author ........: Trojan Nguyen
; ===============================================================================================================================
Func _GetReactions(ByRef $link)
	If $link="" then Return SetError(1,0,0)
	$JsonObj = Json_Decode(_INetGetSource($link))
	$i = 0
	While 1
		$id = Json_Get($JsonObj, '["data"][' & $i & ']["id"]')        
		If @error then ExitLoop
		_ArrayAdd($Array, $id)
		$i += 1
	Wend
	$next = Json_Get($JsonObj, '["paging"]["next"]')  
	If @error Then Return $Array
	If $next<>"" and not @error Then
		_GetReactions($next); Gọi đệ quy
	EndIf
	Return $Array
EndFunc

; #FUNCTION# ====================================================================================================================
; Name ..........: _GetCMT
; Description ...: Lấy comment từ ID Post
; Syntax ........: _GetCMT(ByRef $link)
; Parameters ....: ByRef $link          - Link.
; Return values .: Success : Trả về danh sach ID user bình luận
;                  Failure : @error set về 0
; Author ........: Trojan Nguyen
; ===============================================================================================================================
Func _GetCMT(ByRef $link)
	If $link="" then Return SetError(1,0,0)
	$JsonObj = Json_Decode(_INetGetSource($link))
	$i = 0
	While 1
		$id = Json_Get($JsonObj, '["comments"]["data"][' & $i & ']["from"]["id"]')        
		If @error then ExitLoop
		_ArrayAdd($ArrayCMT, $id)
		$i += 1
	Wend
	$next = Json_Get($JsonObj, '["paging"]["next"]')  
	If @error Then Return $ArrayCMT
	If $next<>"" and not @error Then
		_GetCMT($next); Gọi đệ quy
	EndIf
	Return $ArrayCMT
EndFunc

; #FUNCTION# ====================================================================================================================
; Name ..........: _GetShare
; Description ...: Lấy số lượng share từ ID Post
; Syntax ........: _GetShare($id, $access_token)
; Parameters ....: $id                  - id post.
;                  $access_token        - Access token.
; Return values .: Success : số lượng share
;                  Failure : @error set về False
; Author ........: Trojan Nguyen
; ===============================================================================================================================
Func _GetShare($id, $access_token)
	If StringInStr($id, "_")=0 or $id="" or $access_token="" then Return SetError(1,0,False)
	$link = "https://graph.facebook.com/v2.8/"&$id&"?fields=shares&access_token=" & $access_token
	$JsonObj = Json_Decode(_INetGetSource($link))
	$count = Json_Get($JsonObj, '["shares"]["count"]')
	ConsoleWrite($count&@CRLF)
	Return $count
EndFunc
