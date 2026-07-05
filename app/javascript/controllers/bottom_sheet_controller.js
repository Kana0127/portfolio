import { Controller } from "@hotwired/stimulus"

// 「＋ 新規目標作成」から下部に出てくるボトムシートの開閉を制御する。
// data-controller="bottom-sheet" を親要素に付け、
//   - トリガー: data-action="bottom-sheet#open"
//   - シート本体: data-bottom-sheet-target="sheet"
//   - オーバーレイやキャンセル: data-action="bottom-sheet#close"
// で使う。
export default class extends Controller {
  static targets = ["sheet"]

  open(event) {
    event.preventDefault()
    this.sheetTarget.classList.add("is-open")
    document.body.classList.add("is-bottom-sheet-open")
  }

  close(event) {
    if (event) event.preventDefault()
    this.sheetTarget.classList.remove("is-open")
    document.body.classList.remove("is-bottom-sheet-open")
  }

  // オーバーレイ部分をクリックしたときだけ閉じる（シート内クリックでは閉じない）
  closeFromOverlay(event) {
    if (event.target === event.currentTarget) {
      this.close(event)
    }
  }
}
