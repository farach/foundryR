.onAttach <- function(libname, pkgname) {
  packageStartupMessage(
    "\n",
    "foundryR - Tidy Interface to Azure AI Foundry\n",
    "==============================================\n",
    "* Check your setup:
  foundry_check_setup()\n",
    "* Set your API key: foundry_set_key()\n",
    "* Set your endpoint: foundry_set_endpoint()\n",
    "* Get started: ?foundry_chat, ?foundry_embed\n",
    "\n",
    "New to Azure? See the README for setup instructions.\n"
  )
  invisible()
}
