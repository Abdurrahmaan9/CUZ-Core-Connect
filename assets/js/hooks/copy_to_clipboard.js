// assets/js/hooks/copy_to_clipboard.js
export const CopyToClipboard = {
  mounted() {
    this.el.addEventListener("click", () => {
      const value = this.el.dataset.value;
      if (!value) return;

      navigator.clipboard.writeText(value).then(() => {
        this.el.setAttribute("data-copied", "");
        clearTimeout(this._copiedTimeout);
        this._copiedTimeout = setTimeout(() => {
          this.el.removeAttribute("data-copied");
        }, 2000);
      });
    });
  },

  destroyed() {
    clearTimeout(this._copiedTimeout);
  },
};
