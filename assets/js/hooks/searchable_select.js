export const SearchableSelect = {
  mounted() {
    const wrapper = this.el;
    const dropdownId = wrapper.getAttribute("data-dropdown-id");
    const searchInput = wrapper.querySelector('[id$="-search"]');
    const displayInput = wrapper.querySelector('[id$="-display"]');
    const hiddenInput = wrapper.querySelector('input[type="hidden"]');
    const optionsList = wrapper.querySelector('[id$="-options-list"]');
    const dropdown = wrapper.querySelector(`#${dropdownId}`);

    if (!dropdown || !optionsList) return;

    // Store original options
    let originalOptions = Array.from(optionsList.children);

    // Close dropdown function
    const closeDropdown = () => {
      dropdown.classList.add("hidden");
      if (searchInput) {
        searchInput.value = "";
        originalOptions.forEach((opt) => {
          opt.style.display = "";
        });
        // Remove "no results" message if exists
        const noResults = optionsList.querySelector(".no-results");
        if (noResults) noResults.remove();
      }
    };

    // Handle search filtering - searches by the label/value (visible text)
    if (searchInput) {
      searchInput.addEventListener("input", (e) => {
        const searchTerm = e.target.value.toLowerCase();

        originalOptions.forEach((option) => {
          // Get the data-label attribute which contains the searchable value
          const label = option.getAttribute("data-label") || option.textContent;
          const text = label.toLowerCase();

          if (text.includes(searchTerm)) {
            option.style.display = "";
          } else {
            option.style.display = "none";
          }
        });

        // Show "No results" if all hidden
        const visibleOptions = originalOptions.filter(
          (opt) => opt.style.display !== "none",
        );
        if (
          visibleOptions.length === 0 &&
          !optionsList.querySelector(".no-results")
        ) {
          const noResults = document.createElement("div");
          noResults.className =
            "no-results px-4 py-3 text-gray-500 text-center";
          noResults.textContent = "No results found";
          optionsList.appendChild(noResults);
        } else {
          const noResults = optionsList.querySelector(".no-results");
          if (noResults) noResults.remove();
        }
      });

      // Handle keyboard navigation
      searchInput.addEventListener("keydown", (e) => {
        if (e.key === "Escape") {
          closeDropdown();
          displayInput.focus();
        }
      });
    }

    // Handle option selection
    const changeHandler = (e) => {
      const inputId = displayInput.id.replace("-display", "");

      if (e.detail.id === inputId) {
        hiddenInput.value = e.detail.value;
        displayInput.value = e.detail.label;

        // Close and reset
        closeDropdown();

        // Dispatch change event for LiveView
        hiddenInput.dispatchEvent(new Event("input", { bubbles: true }));
      }
    };

    window.addEventListener("searchable-select:change", changeHandler);

    // Close dropdown when clicking outside
    const outsideClickHandler = (e) => {
      if (!wrapper.contains(e.target)) {
        closeDropdown();
      }
    };

    document.addEventListener("click", outsideClickHandler);

    // Store cleanup function
    this.handleCleanup = () => {
      window.removeEventListener("searchable-select:change", changeHandler);
      document.removeEventListener("click", outsideClickHandler);
    };
  },

  destroyed() {
    // Clean up event listeners when component is destroyed
    if (this.handleCleanup) {
      this.handleCleanup();
    }
  },
};
