// assets/js/hooks/copy_to_clipboard.js
export const CopyToClipboard = {
  mounted() {
    this.el.addEventListener("click", () => {
      const value = this.el.dataset.value;

      navigator.clipboard.writeText(value).then(() => {
        this.el.dataset.copied = "true";
        setTimeout(() => {
          delete this.el.dataset.copied;
        }, 4000);
      });
    });
  },
};

// export default CopyToClipboard;
