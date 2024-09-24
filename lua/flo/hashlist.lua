---@alias HashKey string

---@class HashNode
---@field prev HashNode
---@field next HashNode
---@field key HashKey

---@class HashList
---@field hash table<HashKey, HashNode>
---@field head HashNode
---@field tail HashNode
local Hashlist = {}

function Hashlist:new(hash)
  assert(hash, 'must provide a hash table')
  local hashlist = { hash = hash, head = {}, tail = {} }
  hashlist.head.next = hashlist.tail
  hashlist.tail.prev = hashlist.head
  return setmetatable(hashlist, { __index = self })
end

setmetatable(Hashlist, { __call = Hashlist.new })

---@param node HashNode
---@return HashNode
function Hashlist:delete(node)
  assert(node ~= self.head and node ~= self.tail)
  self.hash[node.key] = nil
  node.prev.next = node.next
  node.next.prev = node.prev
  return node
end

---@param node HashNode
function Hashlist:delete_all_after(node)
  local to_delete = assert(node.next)
  if to_delete == self.tail then return node end
  repeat
    self.hash[to_delete.key] = nil
    to_delete = to_delete.next
  until to_delete == self.tail
  node.next = self.tail
  self.tail.prev = node
end

---@param node HashNode
---@param inserted HashNode
function Hashlist:insert_after(node, inserted)
  inserted.next = node.next
  node.next.prev = inserted
  inserted.prev = node
  node.next = inserted
  self.hash[inserted.key] = inserted
end

---@param callback fun(node: HashNode):boolean?
function Hashlist:foreach(callback)
  local node = self.head.next
  while node and node ~= self.tail do
    if callback(node) == true then return end
    node = node.next
  end
end

---@param callback fun(node: HashNode):boolean?
function Hashlist:foreach_r(callback)
  local node = self.tail.prev
  while node and node ~= self.head do
    if callback(node) == true then return end
    node = node.prev
  end
end

---@param key HashKey
function Hashlist:access(key)
  local node = self.hash[key]
  node = node and self:delete(node) or { key = key }
  self:insert_after(self.head, node)
end

return Hashlist
