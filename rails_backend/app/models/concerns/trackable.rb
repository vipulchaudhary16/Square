module Trackable
  extend ActiveSupport::Concern

  # Diffs `attrs` against the record's current values for `fields`, returning
  # human-readable "field: old → new" strings for the ones that actually changed.
  def track_changes(attrs, fields)
    fields.filter_map do |f|
      next unless attrs[f].present?
      old_val = send(f)
      new_val = attrs[f]
      "#{f}: #{old_val} → #{new_val}" if old_val.to_s != new_val.to_s
    end
  end
end
