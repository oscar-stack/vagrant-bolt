# A plan that retrieves facts and stores in the inventory for the
# specified nodes.
#
# The $nodes parameter is a list of nodes to retrieve the facts for.
plan facts(TargetSpec $nodes) {
  $result_set = run_task('facts', $nodes)

  $result_set.each |$result| {
    add_facts($result.target, $result.value)
  }

  return $result_set
}
