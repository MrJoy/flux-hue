#
module FluxHue
  class Error < StandardError; end

  class UnauthorizedUser < Error; end
  class InvalidJSON < Error; end
  class ResourceNotAvailable < Error; end
  class MethodNotAvailable < Error; end
  class MissingBody < Error; end
  class ParameterNotAvailable < Error; end
  class InvalidValueForParameter < Error; end
  class ParameterNotModifiable < Error; end
  class InternalError < Error; end
  class LinkButtonNotPressed < Error; end
  class ParameterNotModifiableWhileOff < ParameterNotModifiable; end
  class TooManyGroups < Error; end
  class GroupTooFull < Error; end

  class InvalidUsername < Error; end
  class UnknownError < Error; end
  class NoBridgeFound < Error; end

  # Status code to exception map
  ERROR_MAP = {
    1   => UnauthorizedUser,
    2   => InvalidJSON,
    3   => ResourceNotAvailable,
    4   => MethodNotAvailable,
    5   => MissingBody,
    6   => ParameterNotAvailable,
    7   => InvalidValueForParameter,
    8   => ParameterNotModifiable,
    901 => InternalError,
    101 => LinkButtonNotPressed,
    201 => ParameterNotModifiableWhileOff,
    301 => TooManyGroups,
    302 => GroupTooFull,
  }

  def self.get_error(error)
    # Find error class and return instance
    klass = ERROR_MAP[error["type"].to_i] || UnknownError
    klass.new(error["description"])
  end
end
