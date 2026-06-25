.onAttach <- function(libname, pkgname) {
  packageStartupMessage(
    "\n",
    "foundryR - Tidy Azure AI Foundry workflows\n",
    "==========================================\n",
    "* Check your setup:
  foundry_check_setup()\n",
    "* Set your API key: foundry_set_key()\n",
    "* Set your endpoint: foundry_set_endpoint()\n",
    "* Get started: ?foundry_response, ?foundry_groundedness\n",
    "\n",
    "New to Azure? See the README for setup instructions.\n"
  )
  invisible()
}
