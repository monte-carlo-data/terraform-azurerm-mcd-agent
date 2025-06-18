# Private DNS zones used for storage private links
resource "azurerm_private_dns_zone" "dns_storage_blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.mcd_agent_rg.name
}

resource "azurerm_private_dns_zone" "dns_storage_file" {
  name                = "privatelink.file.core.windows.net"
  resource_group_name = azurerm_resource_group.mcd_agent_rg.name
}

resource "azurerm_private_dns_zone" "dns_storage_queue" {
  name                = "privatelink.queue.core.windows.net"
  resource_group_name = azurerm_resource_group.mcd_agent_rg.name
}

resource "azurerm_private_dns_zone" "dns_storage_table" {
  name                = "privatelink.table.core.windows.net"
  resource_group_name = azurerm_resource_group.mcd_agent_rg.name
}

# Link these zones to the VNet
resource "azurerm_private_dns_zone_virtual_network_link" "dns_storage_blob" {
  name                  = "dns_storage_blob_link"
  resource_group_name   = azurerm_resource_group.mcd_agent_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.dns_storage_blob.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "dns_storage_file" {
  name                  = "dns_storage_file_link"
  resource_group_name   = azurerm_resource_group.mcd_agent_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.dns_storage_file.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "dns_storage_queue" {
  name                  = "dns_storage_queue_link"
  resource_group_name   = azurerm_resource_group.mcd_agent_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.dns_storage_queue.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "dns_storage_table" {
  name                  = "dns_storage_table_link"
  resource_group_name   = azurerm_resource_group.mcd_agent_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.dns_storage_table.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}
