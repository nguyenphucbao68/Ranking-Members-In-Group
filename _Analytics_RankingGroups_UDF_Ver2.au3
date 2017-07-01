;_Analytics_RankingGroups.au3
#include-once
#include <array.au3>
#include <string.au3>
#include <Inet.au3>
#include "JSON.au3"

#cs INFO
Analytics Ranking Group Ver 2.0
Coded by Trojan Nguyen ~ Jack (New Username) (fb.com/trojan.nguyen.103)
#ce
_XulyRank()
; #FUNCTION# ====================================================================================================================
; Name ..........: _XulyRank
; Description ...: Tiền hành chạy hệ thống
; Syntax ........: _XulyRank()
; Author ........: Trojan Nguyen (Jack - New Username)
; ===============================================================================================================================_XulyRank()
Func _XulyRank()
	Global $Array2d = Json_ObjCreate();
	Local $access_token, $LimitTime, $ngay, $tuan, $thang, $id_group, $link, $i, $ArrayRanking[0][4]
	$access_token= "Token của bạn"
	$LimitTime =  _DateDiff('s', "1970/01/01 00:00:00", _NowCalc()) ; Lấy time hiện tại (convert to seconds)
	$ngay = 86400 ; tổng giây một ngày
	$tuan = 604800 ; tổng giây một tuần
	$thang = 2592000 ; tổng giây một tháng
	$id_group = "ID Group của bạn";Vd : 364997627165697 (J2team)
	$link = "https://graph.facebook.com/v2.8/"&$id_group&"/feed?limit=500&fields=from,updated_time&access_token="&$access_token
	_GetPost2($access_token, $link, $LimitTime-$thang)
	For $tam in $Array2d
		$tam = Json_get($Array2d, "."&$tam&"[id]")&"|"&Json_get($Array2d, "."&$tam&"[name]")&"|"&Json_get($Array2d, "."&$tam&"[points]")&"|"&Json_get($Array2d, "."&$tam&"[totalPosts]")
		ConsoleWrite($tam)
		_ArrayAdd($ArrayRanking, $tam)
	Next
	For $i = 0 to UBound($ArrayRanking, 1) - 1
		$ArrayRanking[$i][2] = number($ArrayRanking[$i][2]) ; Chuyển điểm thành dạng số đếm
	Next
 	_ArraySort($ArrayRanking,1,0,0,2)
	_ArrayDisplay($ArrayRanking)
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
		$User_Name = Json_Get($JsonObj, '["data"][' & $i & ']["from"]["name"]')
		If @error then ExitLoop
		$point += 3
		$post_id = Json_Get($JsonObj, '["data"][' & $i & ']["id"]')
		If @error then ExitLoop
		ConsoleWrite($post_id&@CRLF)
		$sharecount = _GetShare($post_id, $access_token)
		If $sharecount <> False then $point += $sharecount*1
		$linkReactions = "https://graph.facebook.com/v2.8/"&$post_id&"/reactions?limit=1000&access_token="&$access_token
		Global $Array = Json_ObjCreate()
		$check = _GetReactions($linkReactions)
		
		If $check=false Then
			Json_Put($Array2d, "."&$actor_id&"[id]", $actor_id)
			Json_Put($Array2d, "."&$actor_id&"[name]", $User_Name)
			Json_Put($Array2d, "."&$actor_id&"[points]", Json_Get($Array2d, "."&$actor_id&"[points]")+1)
			Json_Put($Array2d, "."&$actor_id&"[totalPosts]", Json_Get($Array2d, "."&$actor_id&"[totalPosts]"))
		Else
			$point += $check*1 ; Tăng điểm cho người đăng bài dựa trên số lượng like
		EndIf
		
		For $tam in $Array 
			$id = Json_Get($Array, "."&$tam&"[id]")
			$name = Json_Get($Array, "."&$tam&"[name]")
			Json_Put($Array2d, "."&$id&"[id]", $id)
			Json_Put($Array2d, "."&$id&"[name]", $name)
			Json_Put($Array2d, "."&$id&"[points]", Json_Get($Array2d, "."&$id&"[points]")+1)
			Json_Put($Array2d, "."&$id&"[totalPosts]", Json_Get($Array2d, "."&$id&"[totalPosts]"))
		Next
		
		$linkCMT = "https://graph.facebook.com/v2.8/"&$post_id&"?limit=1000&fields=comments&access_token="&$access_token
		Global $ArrayCMT = Json_ObjCreate()
		$check = _GetCMT($linkCMT)
		
		If $check=false Then
			Json_Put($Array2d, "."&$actor_id&"[id]", $actor_id)
			Json_Put($Array2d, "."&$actor_id&"[name]", $User_Name)
			Json_Put($Array2d, "."&$actor_id&"[points]", Json_Get($Array2d, "."&$actor_id&"[points]")+2)
			Json_Put($Array2d, "."&$actor_id&"[totalPosts]", Json_Get($Array2d, "."&$actor_id&"[totalPosts]"))
		Else
			$point += $check*2 ;Tăng điểm cho người đăng bài dựa trên số lượng cmt
		EndIf
		
		For $tam in $ArrayCMT 
			$id = Json_Get($ArrayCMT, "."&$tam&"[id]")
			$name = Json_Get($ArrayCMT, "."&$tam&"[name]")
			Json_Put($Array2d, "."&$id&"[id]", $id)
			Json_Put($Array2d, "."&$id&"[name]", $name)
			Json_Put($Array2d, "."&$id&"[points]", Json_Get($Array2d, "."&$id&"[points]")+1)
			Json_Put($Array2d, "."&$actor_id&"[totalPosts]", Json_Get($Array2d, "."&$actor_id&"[totalPosts]"))
		Next
		Json_Put($Array2d, "."&$actor_id&"[id]", $actor_id)
		Json_Put($Array2d, "."&$actor_id&"[totalPosts]", Json_Get($Array2d, "."&$actor_id&"[totalPosts]")+1)
		Json_Put($Array2d, "."&$actor_id&"[name]", $User_Name)
		Json_Put($Array2d, "."&$actor_id&"[points]", Json_Get($Array2d, "."&$actor_id&"[points]")+$point)
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
Func _FormatTime($string)
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
; Return values .: Success : Trả về sớ lượng Reactions bài viết và Danh Sách User Reactions Bài viết
;                  Failure : @error set về 0
; Author ........: Trojan Nguyen
; ===============================================================================================================================
Func _GetReactions(ByRef $link)
	If $link="" then Return SetError(1,0,False)
	$JsonObj = Json_Decode(_INetGetSource($link))
	$i = 0
	While 1
		$id = Json_Get($JsonObj, '["data"][' & $i & ']["id"]')  
		If @error then ExitLoop  
		$name = Json_Get($JsonObj, '["data"][' & $i & ']["name"]')        
		If @error then ExitLoop
		Json_Put($Array, "."&$id&"[id]", $id)
		Json_Put($Array, "."&$id&"[name]", $name)
		$i += 1
	Wend
	$next = Json_Get($JsonObj, '["paging"]["next"]')  
	If @error Then Return $i-1
	If $next<>"" and not @error Then
		_GetReactions($next); Gọi đệ quy
	EndIf
	Return $i-1
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
	If $link="" then Return SetError(1,0,False)
	$JsonObj = Json_Decode(_INetGetSource($link))
	$i = 0
	While 1
		$id = Json_Get($JsonObj, '["comments"]["data"][' & $i & ']["from"]["id"]')  
		If @error then ExitLoop    
		$name = Json_Get($JsonObj, '["comments"]["data"][' & $i & ']["from"]["name"]')     
		If @error then ExitLoop
		Json_Put($ArrayCMT, "."&$id&"[id]", $id)
		Json_Put($ArrayCMT, "."&$id&"[name]", $name)
;~ 		_ArrayAdd($ArrayCMT, $id)
		$i += 1
	Wend
	$next = Json_Get($JsonObj, '["paging"]["next"]')  
	If @error Then Return True
	If $next<>"" and not @error Then
		_GetCMT($next); Gọi đệ quy
	EndIf
	Return True
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
	if $count then 
		Return $count
	Else 
		Return SetError(1,0,False)
	EndIf
EndFunc
