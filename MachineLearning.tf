terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.86.0"
    }
  }
}

provider "azurerm" {
  features{}
}

data "azurerm_client_config" "current" {}


#Create Resource Group
resource "azurerm_resource_group" "qd_forecast" {
  name     = "qd_forecast"
  location = "eastus"
  tags = {
      "qd_owner"            = "alexandre@quartile.com",
      "qd_creation_date"    = "01-08-2024",
      "qd_creation_channel" = "terraform",
      "qd_project"          = "machinelearning",
      "qd_team"             = "infrastructure",
      "qd_environment"      = "dev/test"
}
}

#Create Application Insights
resource "azurerm_application_insights" "qd_insights" {
  name                = "qd-insights-forecast"
  location            = azurerm_resource_group.qd_forecast.location
  resource_group_name = azurerm_resource_group.qd_forecast.name
  tags                = azurerm_resource_group.qd_forecast.tags
  application_type    = "web"
}

#Create Key Vault
resource "azurerm_key_vault" "kv-forecast" {
  name                = "kv-qd-forecast"
  location            = azurerm_resource_group.qd_forecast.location
  resource_group_name = azurerm_resource_group.qd_forecast.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  tags                = azurerm_resource_group.qd_forecast.tags
  soft_delete_retention_days = 7
  purge_protection_enabled   = false
  sku_name            = "standard"
}

#Create a Storage Account
resource "azurerm_storage_account" "qd-storage" {
  name                     = "qdstorageforecast"
  location                 = azurerm_resource_group.qd_forecast.location
  resource_group_name      = azurerm_resource_group.qd_forecast.name
  tags                     = azurerm_resource_group.qd_forecast.tags
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_container_registry" "qd-registry" {
  name                = "qdregistryforecast"
  location            = azurerm_resource_group.qd_forecast.location
  resource_group_name = azurerm_resource_group.qd_forecast.name
  sku                 = "Basic"
  admin_enabled       = true
}


#Create a Machine Learning
resource "azurerm_machine_learning_workspace" "qd-machinelearning" {
  name                    = "qd-ml-forecast"
  location                = azurerm_resource_group.qd_forecast.location
  resource_group_name     = azurerm_resource_group.qd_forecast.name
  application_insights_id = azurerm_application_insights.qd_insights.id
  key_vault_id            = azurerm_key_vault.kv-forecast.id
  storage_account_id      = azurerm_storage_account.qd-storage.id
  container_registry_id   = azurerm_container_registry.qd-registry.id
  public_network_access_enabled = true
  tags                    = azurerm_resource_group.qd_forecast.tags

  identity {
    type = "SystemAssigned"
  }
}