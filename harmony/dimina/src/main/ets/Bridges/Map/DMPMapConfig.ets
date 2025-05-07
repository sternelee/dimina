import { DMPMap } from '../../Utils/DMPMap';

export interface DMPMapConfig {
  getCustomMarkerInfoView(param: DMPMap): Promise<WrappedBuilder<[object]> | null>;
}

