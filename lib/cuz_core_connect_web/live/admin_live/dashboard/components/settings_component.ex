defmodule CuzCoreConnectWeb.AdminLiveSettingsComponent do
  use CuzCoreConnectWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <div class="bg-base-100 shadow-lg rounded-box">
        <div class="px-4 py-5 sm:p-6">
          <h3 class="text-lg font-semibold text-base-content mb-6">System Configuration</h3>

          <div class="space-y-6">
            <div class="form-control">
              <label class="label">
                <span class="label-text font-medium">System Name</span>
              </label>
              <input type="text" value="UniFlow" class="input input-bordered w-full" />
            </div>

            <div class="form-control">
              <label class="label">
                <span class="label-text font-medium">Default User Role</span>
              </label>
              <select class="select select-bordered w-full">
                <option>Academics</option>
                <option>Student</option>
                <option>Finance</option>
                <option>HOD</option>
              </select>
            </div>

            <div class="form-control">
              <label class="label">
                <span class="label-text font-medium">Email Notifications</span>
              </label>
              <div class="mt-2 space-y-2">
                <label class="label cursor-pointer">
                  <input type="checkbox" checked class="checkbox checkbox-primary" />
                  <span class="label-text">Enable email notifications</span>
                </label>
                <label class="label cursor-pointer">
                  <input type="checkbox" checked class="checkbox checkbox-primary" />
                  <span class="label-text">Send registration confirmations</span>
                </label>
              </div>
            </div>

            <div class="pt-4">
              <button type="button" class="btn btn-primary">Save Changes</button>
            </div>
          </div>
        </div>
      </div>

      <div class="bg-base-100 shadow-lg rounded-box">
        <div class="px-4 py-5 sm:p-6">
          <h3 class="text-lg font-semibold text-base-content mb-6">Backup & Maintenance</h3>

          <div class="space-y-4">
            <div class="flex justify-between items-center">
              <div>
                <p class="text-sm font-medium text-base-content">Last Backup</p>
                <p class="text-sm text-base-content/50">2 hours ago</p>
              </div>
              <button class="btn btn-outline btn-sm">Run Backup</button>
            </div>

            <div class="flex justify-between items-center">
              <div>
                <p class="text-sm font-medium text-base-content">System Maintenance</p>
                <p class="text-sm text-base-content/50">Schedule regular maintenance</p>
              </div>
              <button class="btn btn-outline btn-sm">Configure</button>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
