export const ModalPortal = {
  mounted() {
    this._originalParent = this.el.parentElement
    this._placeholder = document.createComment("modal-portal")
    this._originalParent.insertBefore(this._placeholder, this.el)
    document.body.appendChild(this.el)
  },

  destroyed() {
    if (this._placeholder && this._placeholder.parentNode) {
      this._placeholder.parentNode.removeChild(this._placeholder)
    }

    if (this.el && this.el.parentNode) {
      this.el.parentNode.removeChild(this.el)
    }
  },
}
