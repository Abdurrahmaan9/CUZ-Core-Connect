export const PasswordToggle = {
  mounted() {
    const button = this.el;
    const inputId = button.dataset.target;
    const input = document.getElementById(inputId);

    const showIcon = button.querySelector(".show-icon");
    const hideIcon = button.querySelector(".hide-icon");

    button.addEventListener("click", () => {
      const isPassword = input.type === "password";

      input.type = isPassword ? "text" : "password";

      showIcon.classList.toggle("hidden", !isPassword);
      hideIcon.classList.toggle("hidden", isPassword);
    });
  },
};

// export default PasswordToggle;
